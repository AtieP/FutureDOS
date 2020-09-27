# FutureDOS naming convention
- Everything must be snake-cased. For example, `a_variable`. There are some excemptions though, but they are really rare and shouldn't be imitated.
- Constants, strings and macros must be in uppercase. For example, `STRING1`, `MACRO1`, `SOME_MACRO`.
- Functions must be in lowercase. For example, `print_a_string`.
- Prepend an underscore to functions, macros and constants that should be only used on the same file, but they can also be used externally. There's an exemption for strings if they are sublabeled.
- Prepend two underscores to functions, macros and constants if they mustn't be used outside of the same file. There are some exemptions to use them outside of the original file though, for example, `isr9.asm` from `src/kernel/isr/` uses `__KEYBOARD_LAST_KEY` from `src/kernel/drivers/keyboard.asm`.