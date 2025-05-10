FROM python:3.9-slim AS builder

# 安装必要的工具
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

# 设置环境变量
ENV PORT="7860" NX_PORT="3555" VM_PORT="8001" VL_PORT="8002" \
    MPATH="vms" VPATH="vls" NEZ_KEY="zmmznnzzm" URL="mirror.umd.edu"

# 创建非root用户
RUN useradd -m -u 1000 appuser && \
    apt-get update && \
    apt-get install -y supervisor nginx sudo && \
    mkdir -p /var/log/supervisor /etc/supervisor/conf.d && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 创建必要的目录并设置权限
RUN mkdir -p /app /run/nginx /var/log/nginx /var/lib/nginx && \
    chown -R appuser:appuser /app /var/log/supervisor /etc/supervisor/conf.d && \
    chown -R appuser:appuser /var/log/nginx /var/lib/nginx /run/nginx && \
    # 允许appuser运行nginx和supervisor
    echo "appuser ALL=(ALL) NOPASSWD: /usr/sbin/nginx, /usr/bin/supervisord" >> /etc/sudoers

# 工作目录
WORKDIR /app

# 创建启动脚本
RUN echo '#!/bin/bash' > /app/start.sh && \
    echo 'sed -i \' >> /app/start.sh && \
    echo '  -e "s/7860/${PORT}/g" \' >> /app/start.sh && \
    echo '  -e "s/8001/${VM_PORT}/g" \' >> /app/start.sh && \
    echo '  -e "s/8002/${VL_PORT}/g" \' >> /app/start.sh && \
    echo '  -e "s/3555/${NX_PORT}/g" \' >> /app/start.sh && \
    echo '  -e "s/vms/${MPATH}/g" \' >> /app/start.sh && \
    echo '  -e "s/vls/${VPATH}/g" \' >> /app/start.sh && \
    echo '  -e "s/zmmznnzzm/${NEZ_KEY}/g" \' >> /app/start.sh && \
    echo '  -e "s#\${URL}#${URL}#g" \' >> /app/start.sh && \
    echo '  /app/nginx.conf' >> /app/start.sh && \
    echo 'sudo mv -f /app/nginx.conf /etc/nginx/nginx.conf' >> /app/start.sh && \
    echo 'sudo /usr/bin/supervisord -c /etc/supervisord.conf' >> /app/start.sh && \
    chmod +x /app/start.sh && \
    chown appuser:appuser /app/start.sh

# 从builder阶段复制应用程序
COPY --from=builder --chown=appuser:appuser /app/nx-app /app/nx-app

# 复制配置文件
COPY --chown=appuser:appuser supervisord.conf /etc/supervisord.conf
COPY --chown=appuser:appuser damon.ini /etc/supervisor/conf.d/damon.ini
COPY --chown=appuser:appuser nginx.conf /app/nginx.conf

# 为Hugging Face空间添加健康检查路由 - 使用端口7860
RUN echo 'server {\n  listen 7860;\n  location = /healthz {\n    return 200 "OK";\n  }\n  location / {\n    proxy_pass http://127.0.0.1:7860;\n  }\n}' > /etc/nginx/sites-available/default && \
    chown appuser:appuser /etc/nginx/sites-available/default

# 创建README文件
RUN echo '# Service Application\n\nThis is a service application running on Hugging Face Spaces.' > /app/README.md && \
    chown appuser:appuser /app/README.md

EXPOSE 7860

# 切换到非root用户
USER appuser

# 启动服务
CMD ["/app/start.sh"]