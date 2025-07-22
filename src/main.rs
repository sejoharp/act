use ini::Ini;
use std::ffi::OsStr;
use std::path::PathBuf;
use std::process::Command;
use std::{env, fs};

pub fn is_git_repo(path: &PathBuf) -> bool {
    if let Ok(entries) = fs::read_dir(path) {
        for entry in entries {
            match entry {
                Ok(entry) => {
                    if entry
                        .path()
                        .file_name()
                        .is_some_and(|subdir| subdir.eq(OsStr::new(".git")))
                    {
                        return true;
                    }
                }
                Err(_e) => (),
            }
        }
    }
    false
}

fn get_url_from_config(path: PathBuf) -> Option<String> {
    let git_config_path = path.join(".git/config");
    if git_config_path.exists() {
        let config_content = fs::read_to_string(git_config_path).ok()?;
        let config = Ini::load_from_str(&config_content).ok()?;
        if let Some(remote_section) = config.section(Some("remote \"origin\"")) {
            return remote_section.get("url").map(|s| s.to_string());
        }
    }
    None
}

// Convert SSH or Git URL to HTTPS
fn convert_to_browser_url(url: String) -> String {
    if url.starts_with("git@github.com:") {
        // Convert git@github.com:user/repo.git → https://github.com/user/repo
        url.replacen("git@github.com:", "https://github.com/", 1)
            .trim_end_matches(".git")
            .to_string()
    } else if url.starts_with("https://github.com/") {
        url.trim_end_matches(".git").to_string()
    } else if url.starts_with("git://github.com/") {
        url.replacen("git://", "https://", 1)
            .trim_end_matches(".git")
            .to_string()
    } else {
        url.to_string()
    }
}

fn find_git_repo_root(current_dir: PathBuf) -> Option<PathBuf> {
    while current_dir != PathBuf::from("/") {
        if is_git_repo(&current_dir) {
            return Some(current_dir);
        } else if let Some(parent) = current_dir.parent() {
            return find_git_repo_root(parent.to_path_buf());
        }
    }
    return None;
}
fn parse_command_line_arguments() -> clap::ArgMatches {
    clap::Command::new("act")
        .about(
            "Opens the GitHub Actions page for the current repository in the default web browser.",
        )
        .version(env!("CARGO_PKG_VERSION"))
        .get_matches()
}
fn main() {
    let _cli = parse_command_line_arguments();

    let current_dir = env::current_dir().unwrap();
    if let Some(repo_root) = find_git_repo_root(current_dir) {
        if let Some(url) = get_url_from_config(repo_root) {
            let browser_url = convert_to_browser_url(url);
            let actions_url = format!("{}/actions", browser_url);
            Command::new("open")
                .arg(&actions_url)
                .output()
                .expect(format!("Failed to open {actions_url} in browser").as_str());
        } else {
            eprintln!("No remote 'origin' found or no 'url' specified.");
        }
    } else {
        eprintln!("No Git repository found in the current directory or its parents.");
    }
}
