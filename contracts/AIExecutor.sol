// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./OrchestrationEngine.sol";

/**
 * @title AIExecutor
 * @notice Chain-3 advisory-only Digital Double surface (Invariant 4.2).
 *
 * Allowed: register/revoke agents, forward advisory hashes.
 * Forbidden: target.call, governance execution, rollback, ledger actuation.
 */
contract AIExecutor is UUPSUpgradeable, AccessControlUpgradeable {
    // -------------------------------------------------------------------------
    // Roles & state
    // -------------------------------------------------------------------------

    bytes32 public constant ADVISOR_ROLE = keccak256("ADVISOR_ROLE");

    OrchestrationEngine public orchestrator;

    /// @notice Registered advisory agents (no execution capability).
    mapping(address => bool) public authorizedAgents;

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    event AdvisoryProcessed(uint256 indexed proposalId, bytes32 advisoryHash);
    event AgentRegistered(address indexed agent);
    event AgentRevoked(address indexed agent);

    // -------------------------------------------------------------------------
    // Lifecycle
    // -------------------------------------------------------------------------

    constructor() {
        _disableInitializers();
    }

    function initialize(address orchestrator_, address governance) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();

        orchestrator = OrchestrationEngine(orchestrator_);

        _grantRole(DEFAULT_ADMIN_ROLE, governance);
        _grantRole(ADVISOR_ROLE, governance);
    }

    // -------------------------------------------------------------------------
    // Agent registry
    // -------------------------------------------------------------------------

    function registerAgent(address agent) external onlyRole(ADVISOR_ROLE) {
        require(agent != address(0), "Invalid agent");
        authorizedAgents[agent] = true;
        emit AgentRegistered(agent);
    }

    function revokeAgent(address agent) external onlyRole(ADVISOR_ROLE) {
        authorizedAgents[agent] = false;
        emit AgentRevoked(agent);
    }

    // -------------------------------------------------------------------------
    // Advisory path (no actuation)
    // -------------------------------------------------------------------------

    /**
     * @notice Forward an advisory hash to OrchestrationEngine.
     * @dev Does not mint revert tokens, call external targets, or mutate ledgers.
     */
    function processAdvisory(
        uint256 proposalId,
        bytes32 advisoryHash,
        bytes calldata signature
    ) external onlyRole(ADVISOR_ROLE) {
        require(_isAuthorizedAdvisor(msg.sender), "Unauthorized AI agent");

        orchestrator.receiveAdvisory(proposalId, advisoryHash, signature);

        emit AdvisoryProcessed(proposalId, advisoryHash);
    }

    // -------------------------------------------------------------------------
    // Internal
    // -------------------------------------------------------------------------

    function _isAuthorizedAdvisor(address account) internal view returns (bool) {
        return authorizedAgents[account] || hasRole(ADVISOR_ROLE, account);
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
