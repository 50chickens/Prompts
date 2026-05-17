Read the documents in C:\git\internal\LinkedIn\documentation\prompts\. these have patterns when implementing the requirements.

functional requirements for open-webui.

Add a volume mount to the open-webui service in `docker/docker-compose.yml` so the open-webui SQLite database survives container restarts.

- Map the container path `/app/backend/data` to `C:\git\internal\LinkedIn\data\docker\open-webui` on the host.
- Create the host folder if it does not exist before the container starts — add this to `Invoke-PreflightCheck` in `invoke-deployment.ps1`.
- Verify: restart the container after creating a saved prompt in open-webui and confirm the prompt survives the restart.

The open-webui SQLite database is stored on the host in the DATA_ROOT folder. All saved prompts, model settings, and conversation history survive container restarts. The recruiter's work is never lost because the container was restarted or updated.
Because the database is persistent, every research conversation is saved. A recruiter can return to a previous assignment conversation and continue where they left off.

## Planned Customisations

The following changes are to be made to the open-webui instance to tailor it for the ELR workflow. All are configuration or admin-panel changes — no code changes to open-webui itself.


**Volume mount — database persistence**
Mount `/app/backend/data` in the open-webui container to `C:\git\internal\LinkedIn\data\docker\open-webui` on the host. The host folder is created by `Invoke-PreflightCheck` before the container starts if it does not already exist.
