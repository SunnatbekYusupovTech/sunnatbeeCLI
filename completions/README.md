# Shell completion

`aidevix <TAB>` agent nomlari va flaglarni avtomatik to'ldiradi.

| Shell | Fayl | Holat |
|-------|------|-------|
| bash | `aidevix.bash` | `install.sh` avtomatik ulaydi |
| zsh | `aidevix.bash` (bashcompinit orqali) yoki native `_aidevix` | bash variantini `install.sh` ulaydi; native variant — qo'lda |
| fish | `aidevix.fish` | qo'lda |

## Qo'lda yoqish

### bash
```bash
echo 'source /path/to/aidevix/completions/aidevix.bash' >> ~/.bashrc
```

### zsh (native — chiroyliroq)
```bash
mkdir -p ~/.zsh/completions
cp completions/_aidevix ~/.zsh/completions/_aidevix
# ~/.zshrc:
#   fpath=(~/.zsh/completions $fpath)
#   autoload -U compinit && compinit
```

### fish
```bash
cp completions/aidevix.fish ~/.config/fish/completions/aidevix.fish
```

> 💡 Homebrew bilan o'rnatilganda bash/zsh/fish completion'lari avtomatik
> ulanadi (`packaging/homebrew/aidevix.rb` ga qarang).
