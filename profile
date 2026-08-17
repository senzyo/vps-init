# /etc/profile

# PATH 追加函数（防重复添加）
append_path () {
    case ":$PATH:" in
        *:"$1":*)
            ;;
        *)
            PATH="${PATH:+$PATH:}$1"
    esac
}

# 补充必需路径
append_path '/usr/local/sbin'
append_path '/usr/local/bin'
append_path '/usr/sbin'
append_path '/usr/bin'
append_path '/sbin'
append_path '/bin'
append_path "$HOME/.local/bin"

export PATH

# 纯 Shell 方式加载 /etc/profile.d/
if test -d /etc/profile.d/; then
        for profile in /etc/profile.d/*.sh; do
                test -r "$profile" && . "$profile"
        done
        unset profile
fi

# 清理排序变量与临时函数
unset -v GLOBSORT
unset -f append_path

# 保留对非 Bash Shell 的默认 PS1 容错支持
if test -z "$BASH" && test "$PS1"; then
    if [ "$(id -u)" -eq 0 ]; then
        PS1='# '
    else
        PS1='$ '
    fi
fi

# 严格严密的 Bash 全局配置加载
if test "$BASH" &&\
   test "$PS1" &&\
   test -z "$POSIXLY_CORRECT" &&\
   test "${0#-}" != sh &&\
   test -r /etc/bash.bashrc
then
        . /etc/bash.bashrc
fi

# 清理古老废弃变量
unset TERMCAP
unset MANPATH
