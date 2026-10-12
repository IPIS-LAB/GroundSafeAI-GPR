# 🛠️ 외부 개발자용 상세 협업 온보딩 가이드 (Developer Onboarding & Workflow Guide)

팀에 합류하신 것을 환영합니다! 본 가이드는 처음 합류한 외부 개발자가 개발 환경을 빠르게 구축하고, 데이터 처리 및 모델 개발 작업을 수행하며, 프로젝트 가이드라인을 준수하여 코드를 제출할 수 있도록 돕는 **실전 상세 지침서**입니다.

---

## 📋 목차
1. [초기 개발 환경 구축 (Setup)](#1-초기-개발-환경-구축-setup)
2. [데이터셋 접근 및 관리 규칙 (Data Pipeline)](#2-데이터셋-접근-및-관리-규칙-data-pipeline)
3. [일일 작업 워크플로우 (Daily Workflow)](#3-일일-작업-워크플로우-daily-workflow)
4. [Jupyter Notebook 작업 수칙](#4-jupyter-notebook-작업-수칙)
5. [Pull Request (PR) 작성 및 코드 리뷰 제출](#5-pull-request-pr-작성-및-코드-리뷰-제출)
6. [자주 발생하는 문제 및 해결 FAQ](#6-자주-발생하는-문제-및-해결-faq)

---

## 1. 초기 개발 환경 구축 (Setup)

### 1-1. 저장소 클론 및 브랜치 이동
```bash
# 저장소 클론
git clone https://github.com/IPIS-LAB/GroundSafeAI-GPR.git
cd GroundSafeAI-GPR

# 통합 개발 브랜치(dev)로 이동
git checkout dev
```

### 1-2. 가상환경 생성 및 패키지 설치
버전 충돌을 방지하기 위해 Docker 기반 개발환경 사용을 필수화합니다.

```bash
# Build Docker Image
docker build -t groundsafe-ai:dev .

# Run Docker Container
docker run --gpus all -it \
  --name dev_container \
  -v (code):/workspace/code \
  -v (data):/workspace/data \
  -p 8888:8888 \
  groundsafe-ai:dev /bin/bash
```

### 1-3. 환경 변수(`.env`) 설정
저장소의 루트 디렉토리에 `.env` 파일을 직접 생성하고 필요한 API Key 및 데이터 접근 정보를 작성합니다.
*(주의: `.env` 파일은 절대 Git에 포함되어서는 안 되며, `.gitignore`에 등록되어 있습니다.)*

```env
# .env 예시
DATA_STORAGE_URL=https://your-s3-or-storage-bucket.com/datasets
WANDB_API_KEY=your_wandb_api_key_here
CUDA_VISIBLE_DEVICES=0
```

---

## 2. 데이터셋 접근 및 관리 규칙 (Data Pipeline)

### 2-1. 데이터셋 접근
* 데이터셋은 Git에 커밋하지 않고 로컬(동일한 파일트리)에서 접근하는 방식으로 활용합니다.
```bash
# DVC 설치 및 데이터 동기화 예시
pip install dvc[s3]
dvc pull
```
* 로컬 경로는 기본적으로 `data/` 디렉토리를 사용하며, 이 폴더 내 모든 파일은 `.gitignore` 처리되어 있습니다. 
* repository 외의 디렉토리에 저장 후 접근해도 무방합니다. 이 때는 소스 코드 및 설정 파일에서는 항상 컨테이너 내부의 마운트 경로만 참조하도록 작성합니다.
```bash
# src/dataset/loader.py (공통 코드)
import os

# 컨테이너 내부 통일 경로 지정
DATASET_DIR = "/workspace/data"

def load_images():
    image_path = os.path.join(DATASET_DIR, "train/images")
    # ... 데이터 로드 로직
```

### 2-2. 용량 제한 규칙
* **Git Commit 파일 크기 제한:** **100KB 이상의 데이터 파일**(`.csv`, `.png`, `.jpg`, `.json`) 및 **모델 가중치 파일**(`.pt`, `.pth`, `.onnx`, `.bin`, `.safetensors`)은 Git 커밋을 **엄격히 금지**합니다.
* 모델 가중치는 학습 스크립트 실행 후 `artifacts/` 또는 `runs/` 폴더에 생성되도록 설정되어 있으며, 이 역시 `.gitignore` 대상입니다.

---

## 3. 일일 작업 워크플로우 (Daily Workflow)

### STEP 1: Issue 작성 또는 할당 확인
1. GitHub 저장소의 **Issues** 탭에서 본인이 담당할 Issue를 확인하거나, 새로운 기능/수정건이 있다면 Issue를 직접 작성합니다.
2. Issue 번호를 확인합니다 (예: `#12`).

### STEP 2: 최신 `develop` 반영 및 Feature 브랜치 생성
작업 시작 전 항상 `develop` 브랜치의 최신 코드를 가져옵니다.

```bash
git checkout develop
git pull origin develop

# feature/#이슈번호-기능명 형태로 브랜치 생성 및 이동
git checkout -b feature/#12-yolo-detection-model
```

### STEP 3: 코드 작성 및 커밋 (Commit)
* 커밋은 기능 단위로 명확하게 분리하여 작성합니다.
* **Commit Message Convention** 규칙을 준수합니다.

```bash
# 변경 사항 확인 및 Stage 추가
git status
git add src/models/yolo.py

# 컨벤션에 맞춘 커밋 작성
git commit -m "feat(model): YOLOv8 모델 백본 모듈 구현 (#12)"
```

### STEP 4: 원격 저장소에 Push
```bash
git push origin feature/#12-yolo-detection-model
```

---

## 4. Jupyter Notebook 작업 수칙

실험 목적으로 `.ipynb` 파일을 사용할 경우, Diff 폭탄 및 개인정보/실행 결과 유출을 방지하기 위해 다음을 준수합니다.

1. **저장 전 Clear Output 실행:**
   * VS Code / Jupyter Lab: `Kernel` $\rightarrow$ `Restart Kernel and Clear All Outputs` 실행 후 저장.
2. **`nbstripout` 도구 설치 권장:**
   * 커밋 시 자동 실행 결과 제거 도구를 설정할 수 있습니다.
   ```bash
   pip install nbstripout
   nbstripout --install
   ```

---

## 5. Pull Request (PR) 작성 및 코드 리뷰 제출

### 5-1. PR 생성 절차
1. GitHub 저장소의 **Pull Requests** 탭으로 이동하여 **New pull request** 버튼을 누릅니다.
2. **Base Branch:** `develop` / **Compare Branch:** 본인의 `feature/#이슈번호-기능명`을 선택합니다.
3. PR 제목 양식: `[Feat] YOLOv8 모델 학습 파이프라인 구현 (#12)`
4. PR 본문 템플릿 항목을 성실히 작성합니다:
   * **개요/작업내용:** 핵심 변경 사항 기술
   * **테스트 및 검증 지표:** mAP, Loss, Inference Time 등 성능 결과 첨부
   * **자체 체크리스트:** `.env` 및 대용량 데이터 커밋 여부 재확인

### 5-2. 리뷰 반영 및 승인 받기
* PR 작성 후 최소 1명 이상의 리뷰어(관리자 또는 동료)를 **Reviewers**에 지정합니다.
* 리뷰어가 코드 수정 요청(Request Changes)을 남기면, 해당 피드백을 반영하여 로컬에서 수정 후 커밋 $\rightarrow$ 다시 `push`합니다. (PR은 자동으로 업데이트됩니다.)
* **Approve**를 획득하고 CI 테스트가 통과되면, 관리자가 **Squash and Merge**를 진행합니다.

---

## 6. 자주 발생하는 문제 및 해결 FAQ

### Q1. `develop` 브랜치에 다른 사람이 올린 최신 코드가 합쳐졌어요. 내 브랜치에 어떻게 반영하나요?
```bash
git checkout develop
git pull origin develop
git checkout feature/#12-yolo-detection-model
git rebase develop
# 충돌(Conflict) 발생 시 코드 수정 후:
git add .
git rebase --continue
```

### Q2. 실수로 대용량 모델 파일(`.pt`)을 커밋했어요. 어떻게 취소하나요?
```bash
# 아직 push하지 않은 경우: 가장 최근 커밋 취소 (파일은 로컬에 유지)
git reset HEAD~1

# 이미 push한 경우: git-filter-repo 또는 BFG Repo-Cleaner를 이용해 히스토리에서 제거 후 관리자에게 알림
```