# ansible-deploy-k8s

완전 오프라인 환경에서 Kubernetes 클러스터를 배포하기 위한 Ansible 번들입니다.
이 레포에는 `/root/ansible` 전체를 압축한 오프라인 패키지를 분할 형태로 제공하며,
복원 스크립트를 통해 동일한 디렉토리 구조를 재구성합니다.

## 구성 결과 (요약)

- HA 구성: hacluster/pcs, VIP, HAProxy
- etcd 클러스터 구성 및 인증서 배포
- containerd 기반 런타임 및 kube 바이너리 설치
- Cilium CNI, CoreDNS, Metrics Server
- Ingress(NGINX) + 인증서/HAProxy 설정
- NFS CSI, 스냅샷 클래스 및 테스트
- kube-prometheus-stack
- Istio, Kiali
- FluxCD
- VPA
- Velero (마지막 단계)

## 레포 구조

- `README.md`
- `ansible-offline-restore.sh`: 복원/검증/압축 해제 스크립트
- `bundle/`: 분할된 오프라인 번들 및 체크섬

복원 후 생성되는 디렉토리:

- `/root/ansible`: 실제 배포에 사용되는 전체 Ansible 프로젝트

## 복원 및 압축 해제

```bash
chmod +x ansible-offline-restore.sh
./ansible-offline-restore.sh
```

수동 복원:

```bash
cat bundle/ansible-offline-20260107.tar.gz.part-* > ansible-offline-20260107.tar.gz
sha256sum -c bundle/ansible-offline-20260107.tar.gz.sha256
tar -xzf ansible-offline-20260107.tar.gz
```

## 배포 실행 순서

```bash
cd /root/ansible
./1_setup_all.sh
./2_apt_setup.sh
./3_start_all.sh
```

- `1_setup_all.sh`: inventory/vars/start 스크립트 생성
- `2_apt_setup.sh`: 오프라인 apt 번들 설치(phase1 일부 태그 실행)
- `3_start_all.sh`: 전체 단계 실행 (Velero는 마지막)

## Phase 상세

- Phase 1: OS 기본 설정(SSH/hostname/openfiles), 오프라인 apt 설치, NFS 서버 구성, chrony 동기화, /etc/hosts 갱신
- Phase 2: sysctl 적용, hacluster/pcs 구성, VIP/HAProxy 설정 및 failover 검증
- Phase 3: 예약(현재 디렉토리만 존재, 플레이북 없음)
- Phase 4: SSH 키 교환, etcd 설치/서비스 구성, CA/서버 인증서 생성 및 배포
- Phase 5: containerd/runc/crictl/nerdctl/cni 설치, kube 바이너리 설치, kubelet 설정
- Phase 5.5: Nexus 설치/SSL 생성/백업 복원
- Phase 6: Cilium 배포/재시작/상태 확인, etcd cert 배포, CoreDNS 설정, DNS autoscaler, Metrics Server 배포/검증, kubelet clusterDNS 갱신
- Phase 7: kubeconfig/kubelet 서버 주소 정합성 맞춤
- Phase 8: 인증서 생성/배포, HAProxy 설정, NGINX Ingress 배포 및 포트 확인
- Phase 9: NFS CSI 배포, VolumeSnapshotClass 생성, PVC/스냅샷 테스트 및 정리
- Phase 10: kube-prometheus-stack 배포/검증
- Phase 11: Istio 배포/검증
- Phase 12: Kiali 배포/검증
- Phase 13: FluxCD 배포/검증
- Phase 14: Velero 배포/검증 (최종 단계로 실행 권장)
- Phase 15: VPA 배포 + 서비스 계정 토큰 생성

## 사전 확인 (필수)

- `ansible/inventory.ini`와 `ansible/vars.yml`을 환경에 맞게 수정
- Ubuntu 22.04/24.04 지원
- root 권한 필요

주요 설정 파일:

- `/root/ansible/inventory.ini`: 노드 인벤토리
- `/root/ansible/vars.yml`: 클러스터 네트워크/도메인/노드/스토리지/컴포넌트 설정

## development-package 구성

- apt 오프라인 번들: `apt-packages-ubuntu22.04.tar.gz`, `apt-packages-ubuntu24.04.tar.gz`
- apt 목록: `apt-packages-ubuntu22.04.txt`, `apt-packages-ubuntu24.04.txt`
- 기본 패키지 목록: `apt-base-packages-ubuntu22.04.txt`, `apt-base-packages-ubuntu24.04.txt`
- NFS 오프라인 번들: `nfs-common-package-ubuntu22.04.tar.gz`, `nfs-common-package-ubuntu24.04.tar.gz`
- NFS 목록: `nfs-common-packages-ubuntu22.04.txt`, `nfs-common-packages-ubuntu24.04.txt`
- Cilium 번들: `cilium.tar.gz`, `cilium/`
- CoreDNS 번들: `coredns/`
- DNS Autoscaler 번들: `dns-autoscaler/`
- Metrics Server 번들: `metrics-server.tar.gz`, `metrics-server/`
- k9s: `k9s_linux_amd64.deb`
- Nexus: `nexus3-3.63.0.tar`, `nexus-backup.tar.gz`
- Java(포터블): `java-1.8.0-openjdk-portable-1.8.0.452.b09-1.portable.jdk.el.x86_64.tar.xz`
- K8s 바이너리: `kube-v1.30.12/`

## 컴포넌트 버전 (번들 기준)

| Component | Version / Source |
| --- | --- |
| Kubernetes | `v1.30.12` |
| containerd | `1.7.22` |
| runc | `1.1.12` |
| crictl | `1.30.1` |
| nerdctl | `2.0.2` |
| CNI plugins | `v1.3.0` |
| etcd | `v3.5.15` |
| Helm | `v3.12.3` |
| Cilium | `1.16.1` (chart appVersion) |
| Ingress NGINX | `4.11.2` (chart) |
| NFS CSI | `v4.9.0` (chart) |
| Istio | `1.22.3` (base/istiod/gateway charts) |
| Kiali | `1.82.0` (chart) |
| Velero | `9.0.0` (chart) |
| Nexus | `3.63.0` (bundle) |
| Java (portable) | `1.8.0.452` |

참고:
- kube-prometheus-stack, FluxCD, VPA 등은 `development-package/`의 번들에 포함되어 있으며, 세부 버전은 해당 디렉토리/매니페스트에서 확인 가능합니다.

## 선택 실행

- 특정 phase 실행:
  ```bash
  ansible-playbook -i inventory.ini phase6.yml
  ```
- 선택된 phase 묶음 실행:
  ```bash
  ansible-playbook -i inventory.ini phase_selected.yml
  ```
- 태그 기반 재실행:
  ```bash
  ansible-playbook -i inventory.ini phase14.yml --tags create_values,helm_deploy
  ```

## 참고

- 오프라인 환경 기준 설계이며 외부 네트워크 접근 없이 동작하도록 구성되어 있습니다.
- Velero는 백업 대상(예: MinIO) 준비 후 마지막에 실행하는 것을 권장합니다.
- 대용량 파일 제한 때문에 번들은 분할 파일로 제공합니다.
