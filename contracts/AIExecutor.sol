// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./OrchestrationEngine.sol";
import "./RevertTokenLayer.sol";
import "./KnowledgeLedger.sol";

contract AIExecutor is UUPSUpgradeable, AccessControlUpgradeable {
    bytes32 public constant ADVISOR_ROLE = keccak256("ADVISOR_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    OrchestrationEngine public orchestrator;
    RevertTokenLayer public revertLayer;
    KnowledgeLedger public knowledgeLedger;

    mapping(address => bool) public authorizedAgents; // Multi-agent swarm registry

    event AdvisoryProcessed(uint256 indexed proposalId, bytes32 advisoryHash);
    event ActionExecuted(uint256 indexed proposalId, bytes32 payloadHash);
    event RevertTriggered(uint256 indexed proposalId, uint256 revertTokenId);

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _orchestrator,
        address _revertLayer,
        address _knowledgeLedger,
        address _governance
    ) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();

        orchestrator = OrchestrationEngine(_orchestrator);
        revertLayer = RevertTokenLayer(_revertLayer);
        knowledgeLedger = KnowledgeLedger(_knowledgeLedger);

        _grantRole(DEFAULT_ADMIN_ROLE, _governance);
        _grantRole(ADVISOR_ROLE, _governance);
        _grantRole(EXECUTOR_ROLE, _governance);
    }

    /**
     * @notice Register AI agent under SBT consent (chain3 swarm)
     */
    function registerAgent(address agent) external onlyRole(ADVISOR_ROLE) {
        authorizedAgents[agent] = true;
    }

    /**
     * @notice Process advisory from Digital Double Brain (chain3) — Invariant 4.2 & 5.1
     */
    function processAdvisory(
        uint256 proposalId,
        bytes32 advisoryHash,
        bytes calldata signature
    ) external onlyRole(ADVISOR_ROLE) {
        require(authorizedAgents[msg.sender], "Unauthorized AI agent");

        // Forward to OrchestrationEngine for validation
        orchestrator.receiveAdvisory(proposalId, advisoryHash, signature);

        emit AdvisoryProcessed(proposalId, advisoryHash);
    }

    /**
     * @notice Execute authorized payload (called only via OrchestrationEngine)
     */
    function executeAuthorized(
        uint256 proposalId,
        address target,
        bytes calldata data,
        bytes32 payloadHash
    ) external onlyRole(EXECUTOR_ROLE) {
        require(authorizedAgents[msg.sender] || hasRole(EXECUTOR_ROLE, msg.sender), "Unauthorized executor");

        (bool success, ) = target.call(data);
        require(success, "Execution failed");

        // Record to KnowledgeLedger
        knowledgeLedger.recordEntry(
            keccak256(data),
            bytes32(0), // state root updated post-execution
            proposalId,
            keccak256(abi.encodePacked(proposalId, payloadHash))
        );

        emit ActionExecuted(proposalId, payloadHash);
    }

    /**
     * @notice Trigger revert through governance path
     */
    function triggerRevert(uint256 proposalId, uint256 revertTokenId, bytes calldata inverseCalldata) 
        external onlyRole(EXECUTOR_ROLE) 
    {
        revertLayer.requestRollback(revertTokenId, inverseCalldata);
        emit RevertTriggered(proposalId, revertTokenId);
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
