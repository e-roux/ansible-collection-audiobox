import os
import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ["MOLECULE_INVENTORY_FILE"]
).get_hosts("all")


def test_architecture_is_arm64(host):
    """Verify we're testing on ARM64 architecture."""
    arch = host.check_output("uname -m")
    assert arch == "aarch64"


def test_debian_version(host):
    """Verify we're on Debian Trixie (13)."""
    release = host.file("/etc/debian_version").content_string.strip()
    assert release.startswith("trixie") or "13" in release


def test_mediaplayer_user_exists(host):
    """Test that mediaplayer user is created."""
    user = host.user("mediaplayer")
    assert user.exists
    assert user.group == "mediaplayer"


def test_arm64_packages_installed(host):
    """Test that ARM64 packages are installed correctly."""
    packages = ["mpd", "mpc", "openjdk-17-jre-headless"]
    for package in packages:
        pkg = host.package(package)
        assert pkg.is_installed


def test_mediaplayer_directory_structure(host):
    """Test directory structure is created correctly."""
    install_dir = "/opt/mediaplayer/mediaplayer"
    assert host.file(install_dir).is_directory
    assert host.file(f"{install_dir}/scripts").is_directory


def test_configuration_files_present(host):
    """Test that configuration files are generated."""
    config_files = [
        "/opt/mediaplayer/mediaplayer/app.properties",
        "/opt/mediaplayer/mediaplayer/RadioList.json",
        "/opt/mediaplayer/mediaplayer/InputSources.xml",
    ]
    for config_file in config_files:
        assert host.file(config_file).exists


def test_systemd_service_installed(host):
    """Test that systemd service file is installed."""
    service_file = "/lib/systemd/system/mediaplayer.service"
    assert host.file(service_file).exists
    assert host.file(service_file).contains("ExecStart")


def test_gpiozero_available(host):
    """Test that gpiozero Python package is available."""
    result = host.run("python3 -c 'import gpiozero; print(gpiozero.__version__)'")
    assert result.rc == 0
    assert result.stdout.strip() != ""


def test_mediaplayer_user_permissions(host):
    """Test that mediaplayer user has correct permissions."""
    user = host.user("mediaplayer")
    assert user.home == "/opt/mediaplayer/mediaplayer"
    assert user.shell == "/usr/sbin/nologin" or user.shell == "/bin/false"


def test_scripts_directory_permissions(host):
    """Test that scripts directory has correct permissions."""
    scripts_dir = host.file("/opt/mediaplayer/mediaplayer/scripts")
    assert scripts_dir.is_directory
    assert scripts_dir.user == "mediaplayer"
    assert scripts_dir.group == "mediaplayer"
