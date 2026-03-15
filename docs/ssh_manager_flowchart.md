graph TD
    A[Start: SSHManagerPage] --> B{SSHService.isConnected?}
    B -- No --> C[Display 'NO ACTIVE UPLINK' Message]
    B -- Yes --> D[Show Loading Indicator]
    D --> E[Call SSHService.listTmuxSessions]
    E --> F[Execute 'tmux list-sessions -F "#S"']
    F --> G[Parse Output into Session List]
    G --> H[Update UI with Session Cards]
    H --> I{User Action?}
    I -- Refresh --> D
    I -- Kill Session --> J[Show Confirmation Dialog]
    J -- Confirm --> K[Call SSHService.killTmuxSession]
    K --> L[Execute 'tmux kill-session -t name']
    L --> D
    I -- Login to Session --> M[context.push '/widgets/ssh' with autoStartCommand]
    M --> N[TalkSSHPage.initState]
    N --> O[Execute 'tmux attach -t name']
