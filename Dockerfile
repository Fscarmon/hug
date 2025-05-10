FROM python:3.9-slim AS builder

# ��װ��Ҫ�Ĺ��� (�˽׶α��ֲ���)
RUN apt-get update && apt-get install -y curl && \
    mkdir -p /app && \
    if [ "$(uname -m)" = "x86_64" ]; then \
        curl -s -L --connect-timeout 30 --retry 3 -o /app/nx-app https://github.com/dsadsadsss/plutonodes/releases/download/xr/linux-amd64-nx-app; \
    elif [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ]; then \
        curl -s -L --connect-timeout 30 --retry 3 -o /app/nx-app https://github.com/dsadsadsss/plutonodes/releases/download/xr/linux-arm64-nx-app; \
    else \
        echo "Unsupported architecture"; \
        exit 1; \
    fi && \
    chmod +x /app/nx-app

FROM python:3.9-slim
# ע�⣺��� nx-app ��һ����ȫ�԰����Ķ������ļ������� Go, Rust ����ģ���
# ���Ҳ���Ҫ Python ��������⣬���Կ���ʹ�ø�С�Ļ��������� debian:slim �� distroless��
# Ŀǰ���� python:3.9-slim ���ṩһ�������� Linux ������

# ���û������� (nx-app Ӧֱ��ʹ����Щ����)
ENV NX_PORT="7860" \
    VM_PORT="8001" \
    VL_PORT="8002" \
    MPATH="vms" \
    VPATH="vls" \
    NEZ_KEY="zmmznnzzm" \
    URL="mirror.umd.edu"

# ������root�û�
# ��� nx-app û���κ��ⲿ�������˴��� apt-get install ���ܲ���Ҫ�κΰ���
RUN useradd -m -u 1000 appuser && \
    apt-get update && \
    apt-get install -y ca-certificates procps
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ����Ӧ�ó���Ŀ¼������Ȩ��
RUN mkdir -p /app && \
    chown -R appuser:appuser /app

# ���ù���Ŀ¼
WORKDIR /app

# ��builder�׶θ���Ӧ�ó���
COPY --from=builder --chown=appuser:appuser /app/nx-app /app/nx-app


# ��¶�˿� (nx-app Ӧ���� $PORT)
EXPOSE 7860

# �л�����root�û�
USER appuser

CMD ["/app/nx-app"]
