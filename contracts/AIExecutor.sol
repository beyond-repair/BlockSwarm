// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./OrchestrationEngine.sol";

/**
 * @title AIExecutor (Chain-3 — Advisory Only)
 * @notice Digital Double advisory surface for BlockSwarm / SAGF.
 *
 * B1 boundary (Invariant 4.2 — AI Cannot Execute):
 *   This contract MUST NOT perform arbitrary external calls, governance
 *   execution, rollback, or other binding state transitions.
 *
 *   Allowed: register agents, process advisory hashes into OrchestrationEngine.
 *   Forbidden: target.call, executeAuthorized, triggerRevert, ledger mutation
 *   that implies post-execution authority.
 *
 * Binding actuation remains on Chain-1 (DAOGovernor / governance roles) and
 * Chain-2 orchestration authorization — never on Chain-3 AI authority.
 */
contract AIExecutor is UUPSUpgradeable, AccessControlUpgradeable {
    bytes32 public constant ADVISOR_ROLE = keccak256("ADVISOR_ROLE");

    OrchestrationEngine public orchestrator;

    /// @notice Multi-agent swarm registry (advisory agents only)
    mapping(address => bool) public authorizedAgents;

    event AdvisoryProcessed(uint256 indexed proposalId, bytes32 advisoryHash);
    event AgentRegistered(address indexed agent);
    event AgentRevoked(address indexed agent);

    constructor() {
        _disableInitializers();
    }

    function initialize(address _orchestrator, address _governance) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();

        orchestrator = OrchestrationEngine(_orchestrator);

        _grantRole(DEFAULT_ADMIN_ROLE, _governance);
        _grantRole(ADVISOR_ROLE, _governance);
    }

    /**
     * @notice Register AI agent under advisory consent (Chain-3 swarm).
     * @dev Does not grant execution capability. Agent may only call processAdvisory
     *      after also holding ADVISOR_ROLE or being registered and invoked by a role holder.
     */
    function registerAgent(address agent) external onlyRole(ADVISOR_ROLE) {
        require(agent != address(0), "Invalid agent");
        authorizedAgents[agent] = true;
        emit AgentRegistered(agent);
    }

    /**
     * @notice Revoke advisory agent registration.
     */
    function revokeAgent(address agent) external onlyRole(ADVISOR_ROLE) {
        authorizedAgents[agent] = false;
        emit AgentRevoked(agent);
    }

    /**
     * @notice Process advisory from Digital Double (Chain-3).
     * @dev Forwards advisory hash to OrchestrationEngine only. No external call,
     *      no revert token mint, no knowledge-ledger mutation from this surface.
     *
     * Invariants: 4.2 (AI cannot execute), 5.1 (advisory provenance).
     */
    function processAdvisory(
        uint256 proposalId,
        bytes32 advisoryHash,
        bytes calldata signature
    ) external onlyRole(ADVISOR_ROLE) {
        require(authorizedAgents[msg.sender] || hasRole(ADVISOR_ROLE, msg.sender), "Unauthorized AI agent");

        // Forward advisory data only — no actuation
        orchestrator.receiveAdvisory(proposalId, advisoryHash, signature);

        emit AdvisoryProcessed(proposalId, advisoryHash);
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
