{
  pkgs,
  writeShellScriptBin,
  runCommandLocal,
}: name: emacsEnv: emacsEarlyInit: let
  initFile = runCommandLocal "init.el" {} ''
    mkdir -p $out
    touch $out/init.el

    cat ${emacsEarlyInit} >> $out/init.el
    echo >> $out/init.el

    for file in ${builtins.concatStringsSep " " emacsEnv.initFiles}
    do
      cat "$file" >> $out/init.el
      echo >> $out/init.el
    done
  '';
  emacsWrapped = pkgs.symlinkJoin {
    name = "emacs-wrapped";
    paths = [emacsEnv];
    buildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/emacs \
        --prefix PATH : "${
        pkgs.lib.makeBinPath [pkgs.emacs-lsp-booster pkgs.nodejs]
      }" \
       --set LSP_USE_PLISTS true \
       --add-flags --init-directory="$initdir"
    '';
  };
in
  writeShellScriptBin name ''
    set +u
    set -x

    export initdir="$(mktemp --tmpdir -d ${name}-XXX)"

    cleanup() {
      rm -rf "$initdir"
    }

    trap cleanup ERR EXIT

    ln -s ${initFile}/init.el "$initdir/init.el"

    ${emacsEnv}/bin/emacs --init-directory "$initdir" "$@"
  ''
