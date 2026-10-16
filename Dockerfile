# requirements.zip 기준: CUDA 12.4 / cuDNN 9 / Python 3.11 / torch 2.5.1+cu124 / ultralytics 8.3.234 (YOLO11 지원)
# 호스트 드라이버 >= 550
FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    VIRTUAL_ENV=/opt/venv \
    PATH=/opt/venv/bin:$PATH

# Ubuntu 22.04 기본 Python은 3.10이라 3.11은 deadsnakes PPA에서 받는다
RUN apt-get update && apt-get install -y --no-install-recommends \
      software-properties-common ca-certificates gnupg \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y --no-install-recommends \
      python3.11 python3.11-venv python3.11-dev \
      libglib2.0-0 unzip git \
    && rm -rf /var/lib/apt/lists/*

RUN python3.11 -m venv /opt/venv && pip install --upgrade pip

COPY docker/requirements.txt /tmp/requirements.txt
RUN pip install --extra-index-url https://download.pytorch.org/whl/cu124 -r /tmp/requirements.txt \
    # ultralytics가 끌어온 GUI용 opencv-python을 headless로 교체
    && pip uninstall -y opencv-python \
    && pip install --force-reinstall --no-deps opencv-python-headless

WORKDIR /workspace/GroundSafeAI-GPR
CMD ["bash"]
