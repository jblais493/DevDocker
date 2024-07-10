FROM alpine:3.19

# Install packages and set up environment in one layer
RUN apk update && \
    for i in 1 2 3 4 5; do \
        apk add --no-cache \
        curl git neovim zsh go nodejs npm python3 py3-pip tmux build-base \
        python3-dev musl-dev linux-headers fzf rust cargo py3-setuptools bash && break || sleep 15; \
    done && \
    python3 -m venv /root/venv && \
    . /root/venv/bin/activate && \
    pip install --upgrade pip && \
    pip install thefuck && \
    pip install pipx && \
    deactivate && \
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone https://github.com/marlonrichert/zsh-autocomplete ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting && \
    git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab && \
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-autocomplete zsh-syntax-highlighting fzf-tab)/' ~/.zshrc && \
    git clone https://github.com/jimeh/tmuxifier.git /root/.tmuxifier && \
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh && \
    curl -sS https://starship.rs/install.sh | sh -s -- --yes && \
    go install golang.org/x/tools/gopls@v0.11.0 && \
    go install github.com/a-h/templ/cmd/templ@latest && \
    cargo install eza

# Copy configuration files
COPY config/.zshrc /root/.zshrc
COPY config/starship.toml /root/.config/starship.toml

# Adjust .zshrc
RUN sed -i 's|/home/joshua/.oh-my-zsh|/root/.oh-my-zsh|g' /root/.zshrc && \
    echo 'export PATH="$PATH:/root/go/bin:/root/.tmuxifier/bin:/root/.cargo/bin:/root/venv/bin"' >> /root/.zshrc && \
    echo 'source /root/venv/bin/activate' >> /root/.zshrc && \
    echo 'eval "$(tmuxifier init -)"' >> /root/.zshrc && \
    echo 'eval "$(zoxide init zsh)"' >> /root/.zshrc && \
    echo 'eval "$(thefuck --alias)"' >> /root/.zshrc

# Set Go environment variables
ENV GOPROXY=https://proxy.golang.org,direct \
    GOSUMDB=sum.golang.org \
    GOTOOLCHAIN=local

RUN go env -w GOPROXY=$GOPROXY GOSUMDB=$GOSUMDB GOTOOLCHAIN=$GOTOOLCHAIN

# Set up workspace
WORKDIR /workspace

# Set default shell to zsh
CMD ["/bin/zsh"]
