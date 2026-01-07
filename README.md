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

## 포함 파일

- `ansible-offline-20260107.tar.gz.part-*`: 분할된 오프라인 번들
- `ansible-offline-20260107.tar.gz.sha256`: 번들 무결성 체크섬
- `ansible-offline-restore.sh`: 복원/검증/압축 해제 스크립트

## 복원 및 압축 해제

```bash
chmod +x ansible-offline-restore.sh
./ansible-offline-restore.sh
```

수동 복원:

```bash
cat ansible-offline-20260107.tar.gz.part-* > ansible-offline-20260107.tar.gz
sha256sum -c ansible-offline-20260107.tar.gz.sha256
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
