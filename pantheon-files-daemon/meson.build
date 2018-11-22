pantheon_files_daemon_files = files (
    'main.vala',
    'FileManager1.vala',
    'marlind-tagging.vala'
)

executable (
    meson.project_name () + '-daemon',
    pantheon_files_daemon_files,

    dependencies : [
        pantheon_files_core_dep,
        dependency ('libnotify', version: '>=0.7.2')
    ],
    install: true,
)
