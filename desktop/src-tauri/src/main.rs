#![cfg_attr(all(not(debug_assertions), target_os = "windows"), windows_subsystem = "windows")]

use std::collections::HashMap;
use tauri::api::process::{Command, CommandEvent};

#[tauri::command]
async fn start_backend(app: tauri::AppHandle) -> Result<(), String> {
    // Provide env vars via HashMap (Tauri v1 API)
    let mut envs = HashMap::new();
    envs.insert("BACKEND_PORT".to_string(), "8787".to_string());

    let (mut rx, _child) = Command::new_sidecar("backend")
        .map_err(|e| e.to_string())?
        .envs(envs)
        .spawn()
        .map_err(|e| e.to_string())?;

    // Pipe sidecar output to the app log (optional)
    tauri::async_runtime::spawn(async move {
        while let Some(event) = rx.recv().await {
            match event {
                CommandEvent::Stdout(line) => println!("[backend] {line}"),
                CommandEvent::Stderr(line) => eprintln!("[backend] {line}"),
                CommandEvent::Terminated(_code) => println!("[backend] terminated"),
                _ => {}
            }
        }
    });

    Ok(())
}

fn main() {
    tauri::Builder::default()
        .setup(|app| {
            let app_handle = app.handle();
            tauri::async_runtime::spawn(async move {
                // Start backend on app startup
                let _ = start_backend(app_handle).await;
            });
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![start_backend])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
