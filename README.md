# ansible-deploy-k8s

완전 오프라인 환경에서 Kubernetes 클러스터를 배포하기 위한 Ansible 번들입니다.
이 레포에는 대용량 번들을 분할한 파일과 복원 스크립트를 제공합니다.
번들을 복원하면 `/root/ansible` 디렉토리 전체가 준비된 상태로 생성됩니다.

## 번들 개요 (/root/ansible)

- `phase1~phase15`: 단계별 배포 플레이북
- `development-package/`: 오프라인 apt 번들 및 추가 패키지
- `1_setup_all.sh`: 인벤토리/vars/start 스크립트 생성 마법사
- `2_apt_setup.sh`: 오프라인 apt 패키지 설치(phase1 일부 태그 실행)
- `3_start_all.sh`: 전체 배포 실행 스크립트 (Velero는 마지막 단계)
- `1.30.12/`: Helm 차트 및 이미지 리소스
- `inventory.ini`, `vars.yml`: 환경 설정 파일

## Phase 상세

- Phase 1: OS 기본 설정(SSH, hostname, openfiles), 오프라인 apt 설치, NFS 서버 구성, chrony 동기화, /etc/hosts 갱신
- Phase 2: sysctl 적용, hacluster/pcs 구성, VIP/HAProxy 설정 및 failover 검증
- Phase 3: 예약(현재 디렉토리만 존재, 플레이북 없음)
- Phase 4: SSH 키 교환, etcd 설치/서비스 구성, CA/서버 인증서 생성 및 배포
- Phase 5: 컨테이너 런타임/도구 설치(containerd, runc, crictl, nerdctl, cni), kube 바이너리 설치, kubelet 설정
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

## 포함 파일

- `bundle/ansible-offline-20260107.tar.gz.part-*`: 분할된 오프라인 번들
- `bundle/ansible-offline-20260107.tar.gz.sha256`: 번들 무결성 체크섬
- `ansible-offline-restore.sh`: 복원/검증/압축 해제 스크립트

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
cd ansible
./1_setup_all.sh
./2_apt_setup.sh
./3_start_all.sh
```

## 사전 확인

- `ansible/inventory.ini`와 `ansible/vars.yml`을 환경에 맞게 수정
- Ubuntu 22.04/24.04 지원
- root 권한 필요

## 참고

- 대용량 파일 제한 때문에 번들은 분할 파일로 제공합니다.
