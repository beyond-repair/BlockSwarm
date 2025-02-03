```python
from web3 import Web3
import json

class DAOAgent:
    def __init__(self, rpc_url, contract_address, abi):
        self.w3 = Web3(Web3.HTTPProvider(rpc_url))
        self.contract = self.w3.eth.contract(
            address=contract_address,
            abi=abi
        )
        self.task_queue = []

    def monitor_proposals(self):
        event_filter = self.contract.events.ProposalCreated.create_filter(fromBlock='latest')
        while True:
            for event in event_filter.get_new_entries():
                self.handle_proposal(event['args']['proposalId'])

    def handle_proposal(self, proposal_id):
        proposal = self.contract.functions.proposals(proposal_id).call()
        if proposal['forVotes'] > proposal['againstVotes']:
            self.execute_proposal(proposal_id)

    def execute_proposal(self, proposal_id):
        tx = self.contract.functions.executeProposal(proposal_id).build_transaction({
            'gas': 200000,
            'nonce': self.w3.eth.get_transaction_count(self.w3.eth.accounts[0])
        })
        signed_tx = self.w3.eth.account.sign_transaction(tx, private_key='YOUR_PRIVATE_KEY')
        self.w3.eth.send_raw_transaction(signed_tx.rawTransaction