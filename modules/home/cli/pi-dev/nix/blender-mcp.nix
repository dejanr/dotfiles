{ pkgs }:

pkgs.python3Packages.buildPythonApplication rec {
  pname = "mcp-for-blender";
  version = "2.1.9";
  pyproject = true;

  src = pkgs.fetchPypi {
    pname = "mcp_for_blender";
    inherit version;
    hash = "sha256-wl9ZuVmKhexjPOk88VX7+AQ3tYRB3nk9YQy5QqND29k=";
  };

  build-system = [ pkgs.python3Packages.setuptools ];
  dependencies = with pkgs.python3Packages; [
    mcp
    httpx
  ];

  postPatch = ''
    substituteInPlace src/blender_mcp/bundled/addon.py \
      --replace-fail $'description="Automatically start the MCP server when Blender loads",\n        default=True' \
        $'description="Automatically start the MCP server when Blender loads",\n        default=False'
  '';

  postInstall = ''
    mkdir -p $out/share/blender-mcp
    cp src/blender_mcp/bundled/addon.py $out/share/blender-mcp/blender_mcp.py
  '';

  makeWrapperArgs = [
    "--set"
    "DISABLE_TELEMETRY"
    "true"
  ];
  DISABLE_TELEMETRY = "true";
  nativeCheckInputs = [ pkgs.python3Packages.pytestCheckHook ];
  pytestFlags = [
    "tests/test_connection_args.py"
    "tests/test_safe_mode.py"
  ];
  pythonImportsCheck = [ "blender_mcp.server" ];

  meta = {
    description = "Blender integration through the Model Context Protocol";
    homepage = "https://github.com/ahujasid/mcp-for-blender";
    license = pkgs.lib.licenses.mit;
    mainProgram = "mcp-for-blender";
  };
}
