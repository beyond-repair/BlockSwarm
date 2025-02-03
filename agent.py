```python
from transformers import pipeline
from web3 import Web3
import json

class DAOAgent:
    def __init__(self, config):
        self.w3 = Web3(Web3.HTTPProvider(config['rpc_url']))
        self.dao_contract = self.w3.eth.contract(
            address=config['dao_address'],
            abi=json.load(open(config['abi_path']))
        )
        self.nlp = pipeline("text-classification", model="bert-base-uncased")
        self.task_queue = []

    def classify_proposal(self, description):
        result = self.nlp(description)[0]
        if result['label'] == 'POSITIVE' and result['score'] > 0.9:
            return "Critical Update"
        elif result['label'] == 'POSITIVE':
            return "Legitimate"
        elif "spam" in description.lower():
            return "Spam"
        else:
            return "Needs Discussion"

    def process_proposal(self, proposal_id):
        proposal = self.dao_contract.functions.proposals(proposal_id).call()
        category = self.classify_proposal(proposal['description'])
        
        if category == "Critical Update":
            self.execute_proposal(proposal_id)
        elif category == "Legitimate":
            self.task_queue.append(proposal_id)
        elif category == "Spam":
            self.dao_contract.functions.reportSpam(proposal_id).transact()

    def execute_proposal(self, proposal_id):
        tx = self.dao_contract.functions.executeProposal(proposal_id).build_transaction({
            'gas': 500000,
            'nonce': self.w3.eth.get_transaction_count(self.w3.eth.accounts[0])
        })
        signed_tx = self.w3.eth.account.sign_transaction(tx, config['private_key'])
        self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)
```