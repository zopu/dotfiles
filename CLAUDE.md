# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for macOS development environment configuration. It uses a modular structure where each tool has its own directory containing configuration files organized for GNU Stow deployment.

## Directory Structure

- `nvim/` - Neovim configuration using LazyVim framework
- `tmux/` - Tmux configuration with Catppuccin theme and custom plugins
- `wezterm/` - WezTerm terminal emulator configuration
- `zsh/` - Zsh shell configuration with aliases and environment setup
- `starship/` - Starship prompt configuration
- `ghostty/` - Ghostty terminal configuration
- `scripts/` - Custom utility scripts for development workflow

## Key Scripts

### Git Worktree Management
- `tm-git-worktree-session.sh` - Creates git worktrees and associated tmux sessions for branch-based development
  - Usage: `tgs <branch-name>` (aliased in zsh)
  - Automatically creates worktree if it doesn't exist
  - Sets up tmux session with nvim and run windows

### Git Cleanup
- `git-safe-cleanup.py` - Safely removes merged branches and their associated worktrees
  - Uses GitHub CLI to identify merged PRs
  - Interactive confirmation before deletion
  - Handles both git branches and worktrees

## Development Environment

### Terminal Setup
- **Terminal**: WezTerm with Catppuccin Mocha theme
- **Shell**: Zsh with Starship prompt
- **Multiplexer**: Tmux with custom prefix (Ctrl+]) and sessionx plugin
- **Editor**: Neovim with LazyVim configuration

### Key Aliases
- `nv` - Opens Neovim with WezTerm TERM setting
- `tgs` - Git worktree session script
- `lg` - Lazygit
- `claude` - Local Claude CLI installation

### Environment Variables
- Node.js managed via nvm
- Python via Homebrew and conda
- Go binaries in ~/go/bin
- Custom scripts in ~/scripts
- Bun package manager configured

## Tmux Configuration
- Prefix key: `Ctrl+]`
- Status bar at top with Catppuccin theme
- Mouse support enabled
- Custom key binding `T` for todo window switching
- TPM plugin manager with sessionx for session management

## Neovim Configuration
- Based on LazyVim framework
- Configuration bootstrapped via `config.lazy`
- Modular plugin structure (many plugins recently removed/disabled)
- Custom keymaps, options, and autocmds in lua/config/

## Installation Pattern
This repository follows GNU Stow conventions where each top-level directory represents a "package" that can be symlinked into the home directory structure using `stow <package-name>`.