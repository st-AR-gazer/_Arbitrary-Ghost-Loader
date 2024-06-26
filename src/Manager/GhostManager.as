namespace GhostLoader {
    [Setting hidden]
    bool S_UseGhostLayer = true;

    void OpenGhostFileDialogWindow() {
        _IO::FileExplorer::OpenFileExplorer(true, IO::FromUserGameFolder("Replays/"));
    }

    void LoadGhost(const string &in filePath) {
        if (filePath.ToLower().EndsWith(".gbx")) {
            string fileName = GetFileName(filePath);
            string destinationPath = Server::serverDirectory + fileName;
            log("Moving file from " + filePath + " to " + destinationPath, LogLevel::Info, 13, "LoadGhost");
            _IO::SafeMoveFileToNonSource(filePath, destinationPath);
            LoadGhostFromUrl(Server::HTTP_BASE_URL + "get_ghost/" + Net::UrlEncode(fileName));
        } else {
            NotifyError("Unsupported file type.");
        }
    }

    string GetFileName(const string &in filePath) {
        array<string> parts = filePath.Split("/");
        return parts[parts.Length - 1];
    }

    void LoadGhostFromUrl(const string &in url) {
        log("Loading ghost from URL: " + url, LogLevel::Info, 27, "LoadGhostFromUrl");
        startnew(LoadGhostFromUrlAsync, url);
    }

    void LoadGhostFromUrlAsync(const string &in url) {
        auto ps = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript);
        auto dfm = ps.DataFileMgr;
        auto gm = ps.GhostMgr;
        auto task = dfm.Ghost_Download(GetFileName(url), url);

        while (task.IsProcessing) {
            yield();
        }

        if (task.HasFailed || !task.HasSucceeded) {
            log('Ghost_Download failed: ' + task.ErrorCode + ", " + task.ErrorType + ", " + task.ErrorDescription + " Url used: " + url, LogLevel::Error, 42, "LoadGhostFromUrlAsync");
            return;
        }

        auto instId = gm.Ghost_Add(task.Ghost, S_UseGhostLayer);
        log('Instance ID: ' + instId.GetName() + " / " + Text::Format("%08x", instId.Value), LogLevel::Info, 47, "LoadGhostFromUrlAsync");

        dfm.TaskResult_Release(task.Id);
    }

    void RemoveAllGhosts() {
        auto gm = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript).GhostMgr;
        gm.Ghost_RemoveAll();
        log("All ghosts removed.", LogLevel::Info, 55, "RemoveAllGhosts");
    }
}