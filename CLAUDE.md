# Homelab Project

## Owner
- **Name**: Augusto Hermosilla
- **Email**: augusto@hermosilla.me (personal/homelab)
- **GitHub**: ajhermosilla

## Related Setup
- **Dotfiles**: https://github.com/ajhermosilla/dotfiles (bare git repo)
- **Main Machine**: MacBook Air M1, macOS Sonoma
- **Shell**: Zsh with starship prompt, modern CLI tools

## Preferences
- Prefer CLI tools over GUIs
- Vim keybindings everywhere (neovim, tmux, neomutt)
- Minimal, well-documented configurations
- Conventional commits (feat:, fix:, docs:, etc.)
- Use modern Rust/Go CLI tools when available

## Tools I Use
- **Containers**: Docker, lazydocker (TUI)
- **Git**: lazygit, gh CLI, GPG signed commits
- **Editor**: Neovim with LazyVim
- **Terminal**: tmux with vim-style navigation
- **Search**: ripgrep, fd, fzf

## Homelab Goals
- Mobile homelab (portable setup)
- Fixed homelab (home server)
- Self-hosted services
- Infrastructure as code
- CLI-first management

## Suggested Structure
```
homelab/
├── docker/
│   ├── media/docker-compose.yml
│   ├── monitoring/docker-compose.yml
│   └── networking/docker-compose.yml
├── ansible/
│   ├── inventory.yml
│   └── playbooks/
├── docs/
│   ├── network-diagram.md
│   ├── hardware.md
│   └── services.md
├── scripts/
└── README.md
```

## Git Configuration
- This repo uses personal email: augusto@hermosilla.me
- GPG signing enabled (key: 8AFCB80F4AC0B02B)
- Directory-based git config handles this automatically

## Session Context
When starting a new session, help me:
1. Document current hardware and services
2. Plan new services with docker-compose
3. Create ansible playbooks for automation
4. Keep everything version controlled
5. Write clear documentation

## Secrets Management
- Never commit secrets to repo
- Use `.env` files (gitignored)
- Consider: SOPS, age encryption, or Vault for sensitive data
