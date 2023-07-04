PACKAGES=(panel holoviews hvplot param datashader geoviews lumen colorcet)
SRC=~/src

conda create -n holoviz python=3.11 ${PACKAGES} jupyterlab pre-commit

conda activate holoviz

install_package() {
    # This should be removed when packages uses pyproject.toml
    export SETUPTOOLS_ENABLE_FEATURES=legacy-editable

    if [ -d "$p" ]; then
        cd $SRC
        cd $p

        # Save current branch and stash files
        BRANCH=$(git branch --show-current)
        DIRTY=$(git status -s -uno | wc -l)
        git stash -m "setup script $(date +%Y-%m-%d_%H.%M)"
        git checkout main

        # Update main
        git fetch
        git pull --tags
        git reset --hard origin/main

        # Clean up
        # if [ "$1" == "CLEAN" ]; then git clean -fxd; fi
        git fetch --all --prune

        # Go back branch and unstash files
        git checkout $BRANCH
        if (($DIRTY > 0)); then git stash pop; fi

    else
        git clone git@github.com:holoviz/$p.git
        cd $p
        pre-commit install --allow-missing-config
    fi
    # .vscode settings
    # sync_vscode_settings

    # pre-commit initialize
    pre-commit

    # Install the package
    conda uninstall --force --offline --yes $p || echo "already uninstalled"
    conda develop .
    python -m pip install --no-deps -e .
    if [["$p" == "panel"]]; then
        panel bundle --all &>/dev/null &
    elif [[ "$p" == "holoviews" ]]; then
        # Don't want the holoviews command
        rm $(which holoviews) || echo "already uninstalled"
    fi
    rm -rf build/
    cd $SRC
}

install_package