/**
 *Submitted for verification at Etherscan.io on 2024-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

contract REALOSS {
    
    // Structure of project
    struct Project {
        int repoid;
        string projectname;
        string ipfsCID;
        string description;
    }

    mapping(int => Project) private projects;
    int private nextRepoId = 1;

    // Function to add project details
    function addProject(string memory projectname, string memory ipfsCID, string memory description) public {
        Project memory newProject = Project(nextRepoId, projectname, ipfsCID, description);
        projects[nextRepoId] = newProject;
        nextRepoId++;
    }

    // Function to get details of a project
    function getProject(int repoid) public view returns (string memory, string memory, string memory) {
        Project memory project = projects[repoid];
        require(project.repoid != 0, "Project not found"); // revert if project is not found
        return (project.projectname, project.ipfsCID, project.description);
    }

    // Function to get all project IDs and names
    function getProjects() public view returns (int[] memory, string[] memory) {
        int[] memory ids = new int[](uint(nextRepoId) - 1);
        string[] memory names = new string[](uint(nextRepoId) - 1);

        for (uint i = 0; i < uint(nextRepoId) - 1; i++) {
            ids[i] = int(i + 1);
            names[i] = projects[int(i + 1)].projectname;
        }

        return (ids, names);
    }

    // Function to search projects by name
    function searchProjectByName(string memory projectname) public view returns (int[] memory, string[] memory, string[] memory) {
        uint count = 0;
        
        // First count matching projects
        for (uint i = 1; i < uint(nextRepoId); i++) {
            if (keccak256(bytes(projects[int(i)].projectname)) == keccak256(bytes(projectname))) {
                count++;
            }
        }

        int[] memory ids = new int[](count);
        string[] memory ipfsCIDs = new string[](count);
        string[] memory descriptions = new string[](count);

        uint index = 0;
        for (uint i = 1; i < uint(nextRepoId); i++) {
            if (keccak256(bytes(projects[int(i)].projectname)) == keccak256(bytes(projectname))) {
                ids[index] = projects[int(i)].repoid;
                ipfsCIDs[index] = projects[int(i)].ipfsCID;
                descriptions[index] = projects[int(i)].description;
                index++;
            }
        }

        return (ids, ipfsCIDs, descriptions);
    }
}
