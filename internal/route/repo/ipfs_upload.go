package repo

import (
	"fmt"
	"net/http"
	"os/exec"
	"strings"

	"gogs.io/gogs/internal/context"
	"gogs.io/gogs/internal/database"
)

// IPFSUploadResponse represents the response from IPFS upload
type IPFSUploadResponse struct {
	Success  bool   `json:"success"`
	IPFSHash string `json:"ipfsHash,omitempty"`
	Error    string `json:"error,omitempty"`
	Gateway  string `json:"gateway,omitempty"`
}

// MagicIPFS handles IPFS upload using magic.sh style approach
func MagicIPFS(c *context.Context) {
	if !c.IsLogged {
		c.JSON(http.StatusUnauthorized, IPFSUploadResponse{
			Success: false,
			Error:   "Authentication required",
		})
		return
	}

	// Get repository
	repo, err := database.Handle.Repositories().GetByName(c.Req.Context(), c.User.ID, c.Params(":reponame"))
	if err != nil {
		c.JSON(http.StatusNotFound, IPFSUploadResponse{
			Success: false,
			Error:   "Repository not found",
		})
		return
	}

	// MAGIC.SH APPROACH: Create clean directory and upload
	repoPath := repo.RepoPath()
	
	// Use git archive to create clean directory with only tracked files
	cmd := exec.Command("sh", "-c", fmt.Sprintf(`
		cd %s && 
		tmpdir=$(mktemp -d) && 
		git archive HEAD | tar -x -C "$tmpdir" && 
		ipfs add -r -Q "$tmpdir" | tail -1 && 
		rm -rf "$tmpdir"
	`, repoPath))
	output, err := cmd.Output()
	if err != nil {
		c.JSON(http.StatusInternalServerError, IPFSUploadResponse{
			Success: false,
			Error:   fmt.Sprintf("Magic IPFS failed: %v", err),
		})
		return
	}
	
	ipfsHash := strings.TrimSpace(string(output))
	
	// Return success response
	c.JSON(http.StatusOK, IPFSUploadResponse{
		Success:  true,
		IPFSHash: ipfsHash,
		Gateway:  fmt.Sprintf("https://ipfs.io/ipfs/%s", ipfsHash),
	})
}