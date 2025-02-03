```javascript
import React, { useState, useEffect } from 'react';
import { useWeb3 } from '../services/web3';

export default function NFCDashboard() {
    const { contract } = useWeb3();
    const [proposals, setProposals] = useState([]);

    useEffect(() => {
        async function loadProposals() {
            const proposalCount = await contract.methods.proposalCount().call();
            const loaded = [];
            for (let i = 0; i < proposalCount; i++) {
                loaded.push(await contract.methods.proposals(i).call());
            }
            setProposals(loaded);
        }
        loadProposals();
    }, [contract]);

    return (
        <div>
            {proposals.map(p => (
                <div key={p.id}>
                    <h3>{p.title}</h3>
                    <p>Votes: {p.forVotes} / {p.againstVotes}</p>
                </div>
            ))}
        </div>
    );
}