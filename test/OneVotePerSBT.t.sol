// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../contracts/DAOGovernor.sol";
import "../contracts/GovernanceNFT.sol";
import "../contracts/RevertTokenLayer.sol";
import "../contracts/OrchestrationEngine.sol";

/**
 * @title OneVotePerSBTTest
 * @notice B2b-1: each SBT holder may vote at most once per proposal.
 *
 *   forge test --match-contract OneVotePerSBTTest -vv
 */
contract OneVotePerSBTTest is Test {
    DAOGovernor internal governor;
    GovernanceNFT internal sbt;

    address internal governance = address(0xA11CE);

    uint256 internal constant MINTER_PK = 0xM1N7; // invalid - use numeric
    uint256 internal minterPk = 0xA01;
    uint256 internal voter1Pk = 0xA11;
    uint256 internal voter2Pk = 0xA22;

    address internal minter;
    address internal voter1;
    address internal voter2;

    function setUp() public {
        minter = vm.addr(minterPk);
        voter1 = vm.addr(voter1Pk);
        voter2 = vm.addr(voter2Pk);

        GovernanceNFT sbtImpl = new GovernanceNFT();
        sbt = GovernanceNFT(
            address(
                new ERC1967Proxy(
                    address(sbtImpl),
                    abi.encodeWithSelector(GovernanceNFT.initialize.selector, governance)
                )
            )
        );

        RevertTokenLayer revImpl = new RevertTokenLayer();
        RevertTokenLayer revertLayer = RevertTokenLayer(
            address(
                new ERC1967Proxy(
                    address(revImpl),
                    abi.encodeWithSelector(RevertTokenLayer.initialize.selector, governance)
                )
            )
        );

        OrchestrationEngine orchImpl = new OrchestrationEngine();
        OrchestrationEngine orch = OrchestrationEngine(
            address(
                new ERC1967Proxy(
                    address(orchImpl),
                    abi.encodeWithSelector(
                        OrchestrationEngine.initialize.selector,
                        address(revertLayer),
                        governance
                    )
                )
            )
        );

        DAOGovernor govImpl = new DAOGovernor();
        governor = DAOGovernor(
            address(
                new ERC1967Proxy(
                    address(govImpl),
                    abi.encodeWithSelector(
                        DAOGovernor.initialize.selector,
                        address(sbt),
                        address(revertLayer),
                        address(orch),
                        governance
                    )
                )
            )
        );

        bytes32 minterRole = sbt.MINTER_ROLE();
        vm.prank(governance);
        sbt.grantRole(minterRole, minter);
    }

    function _mintSbt(address to, bytes32 nfcHash) internal {
        // mintWithNFC requires recover(nfcHash, sig) == msg.sender (minter)
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(minterPk, nfcHash);
        bytes memory sig = abi.encodePacked(r, s, v);
        vm.prank(minter);
        sbt.mintWithNFC(to, nfcHash, sig, bytes32(0));
    }

    function _proof(uint256 voterPk, bytes32 nfcHash) internal pure returns (bytes memory) {
        // castVote: recover(nfcRegistry[voter], proof) == voter
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(voterPk, nfcHash);
        return abi.encodePacked(r, s, v);
    }

    function _propose() internal returns (uint256 pid) {
        vm.prank(governance);
        pid = governor.propose(keccak256("cid"), keccak256("adv"));
    }

    function test_firstVote_countsOnce() public {
        bytes32 nfc = keccak256("nfc-1");
        _mintSbt(voter1, nfc);
        uint256 pid = _propose();

        vm.prank(voter1);
        governor.castVote(pid, true, _proof(voter1Pk, nfc));

        (,,,,, uint256 forVotes, uint256 againstVotes,,) = governor.proposals(pid);
        assertEq(forVotes, 1);
        assertEq(againstVotes, 0);
        assertTrue(governor.hasVoted(pid, voter1));
    }

    function test_secondVote_revertsAlreadyVoted() public {
        bytes32 nfc = keccak256("nfc-2");
        _mintSbt(voter1, nfc);
        uint256 pid = _propose();

        bytes memory proof = _proof(voter1Pk, nfc);

        vm.prank(voter1);
        governor.castVote(pid, true, proof);

        vm.prank(voter1);
        vm.expectRevert(bytes("Already voted"));
        governor.castVote(pid, false, proof);

        (,,,,, uint256 forVotes, uint256 againstVotes,,) = governor.proposals(pid);
        assertEq(forVotes, 1);
        assertEq(againstVotes, 0);
    }

    function test_twoHolders_eachOneVote() public {
        bytes32 nfc1 = keccak256("nfc-a");
        bytes32 nfc2 = keccak256("nfc-b");
        _mintSbt(voter1, nfc1);
        _mintSbt(voter2, nfc2);
        uint256 pid = _propose();

        vm.prank(voter1);
        governor.castVote(pid, true, _proof(voter1Pk, nfc1));

        vm.prank(voter2);
        governor.castVote(pid, false, _proof(voter2Pk, nfc2));

        (,,,,, uint256 forVotes, uint256 againstVotes,,) = governor.proposals(pid);
        assertEq(forVotes, 1);
        assertEq(againstVotes, 1);
        assertTrue(governor.hasVoted(pid, voter1));
        assertTrue(governor.hasVoted(pid, voter2));
    }

    function test_withoutSbt_cannotVote() public {
        uint256 pid = _propose();
        address stranger = address(0xBAD);

        vm.prank(stranger);
        vm.expectRevert();
        governor.castVote(pid, true, hex"00");
    }
}
