// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ✅ Import OpenZeppelin's IERC20 for vote weight
import "https://cdn.jsdelivr.net/npm/@openzeppelin/contracts@4.9.3/token/ERC20/IERC20.sol";
import "https://cdn.jsdelivr.net/npm/@openzeppelin/contracts@4.9.3/access/Ownable.sol";

contract SimpleDAO is Ownable {
    IERC20 public votingToken;
    uint public proposalCount;

    struct Proposal {
        uint id;
        string description;
        uint voteYes;
        uint voteNo;
        uint deadline;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    mapping(uint => Proposal) public proposals;

    event ProposalCreated(uint id, string description, uint deadline);
    event Voted(uint proposalId, address voter, bool support, uint weight);
    event ProposalExecuted(uint proposalId, bool approved);

    constructor(address _tokenAddress) {
        votingToken = IERC20(_tokenAddress);
    }

    /// @notice Create a new proposal
    function createProposal(string calldata description, uint durationInMinutes) external onlyOwner {
        proposalCount++;
        Proposal storage p = proposals[proposalCount];
        p.id = proposalCount;
        p.description = description;
        p.deadline = block.timestamp + durationInMinutes * 1 minutes;

        emit ProposalCreated(p.id, description, p.deadline);
    }

    /// @notice Vote on a proposal
    function vote(uint proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp <= proposal.deadline, "Voting has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");

        uint weight = votingToken.balanceOf(msg.sender);
        require(weight > 0, "No voting power");

        if (support) {
            proposal.voteYes += weight;
        } else {
            proposal.voteNo += weight;
        }

        proposal.hasVoted[msg.sender] = true;

        emit Voted(proposalId, msg.sender, support, weight);
    }

    /// @notice Execute proposal after deadline
    function executeProposal(uint proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.deadline, "Voting still active");
        require(!proposal.executed, "Already executed");

        bool approved = proposal.voteYes > proposal.voteNo;
        proposal.executed = true;

        emit ProposalExecuted(proposalId, approved);
    }

    /// @notice Get proposal result summary
    function getResult(uint proposalId) external view returns (
        string memory description,
        uint yesVotes,
        uint noVotes,
        uint deadline,
        bool executed
    ) {
        Proposal storage p = proposals[proposalId];
        return (p.description, p.voteYes, p.voteNo, p.deadline, p.executed);
    }
}
