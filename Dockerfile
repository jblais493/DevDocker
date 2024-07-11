FROM alpine:3.19

# Install packages and set up environment in one layer
RUN apk update && \
    for i in 1 2 3 4 5; do \
        apk add --no-cache \
        curl git neovim zsh go nodejs npm python3 py3-pip tmux build-base \
        python3-dev musl-dev linux-headers fzf rust cargo py3-setuptools bash \
        ripgrep alpine-sdk --update nodejs npm openssh-client && break || sleep 15; \
    done && \
    python3 -m venv /root/venv && \
    . /root/venv/bin/activate && \
    pip install --upgrade pip && \
    pip install thefuck pynvim && \
    pip install pipx && \
    deactivate

# Diagnostic steps and Neovim config setup
RUN echo "Checking DNS resolution:" && \
    nslookup github.com || echo "nslookup failed" && \
    echo "Checking connectivity:" && \
    ping -c 4 github.com || echo "ping failed" && \
    echo "Attempting to clone Neovim config:"

# Install Oh My Zsh and plugins
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
    for i in 1 2 3 4 5; do git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && break || sleep 15; done && \
    for i in 1 2 3 4 5; do git clone https://github.com/marlonrichert/zsh-autocomplete ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete && break || sleep 15; done && \
    for i in 1 2 3 4 5; do git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting && break || sleep 15; done && \
    for i in 1 2 3 4 5; do git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab && break || sleep 15; done && \
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-autocomplete zsh-syntax-highlighting fzf-tab)/' ~/.zshrc

# Install additional tools
RUN for i in 1 2 3 4 5; do git clone https://github.com/jimeh/tmuxifier.git /root/.tmuxifier && break || sleep 15; done && \
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh && \
    curl -sS https://starship.rs/install.sh | sh -s -- --yes && \
    go install golang.org/x/tools/gopls@v0.11.0 && \
    go install github.com/a-h/templ/cmd/templ@latest

# Attempt to install eza, fallback to exa if it fails
RUN (cargo install eza || apk add --no-cache exa)

# Copy configuration files
COPY config/.zshrc /root/.zshrc
COPY config/starship.toml /root/.config/starship.toml

# Install NvChad
RUN git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1 && \
    nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

# Copy your custom Neovim configuration
COPY config/nvim /root/.config/nvim

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
