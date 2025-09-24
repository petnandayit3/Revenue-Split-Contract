# 💰 Revenue Split Contract

A Clarity smart contract for transparent and automated revenue distribution in the creative industries. Perfect for musicians, content creators, publishers, and any collaborative project requiring fair revenue sharing.

## 🎯 Problem Solved

Creators, producers, and collaborators often face disputes over revenue distribution. Traditional methods involve:
- ❌ Manual calculations prone to errors
- ❌ Lack of transparency in revenue sharing
- ❌ Delays in payments
- ❌ Legal disputes over distribution terms

## ✨ Solution

This smart contract provides:
- ✅ **Automated Distribution**: Revenue is automatically split based on predefined percentages
- ✅ **Transparent Operations**: All transactions are recorded on the blockchain
- ✅ **Consensus-Based Updates**: Changes require agreement from all participants
- ✅ **Real-Time Tracking**: Monitor earnings and distributions in real-time
- ✅ **Dispute Prevention**: Immutable rules prevent conflicts

## 🚀 Features

### Core Functionality
- 📊 **Multiple Revenue Contracts**: Create unlimited revenue-sharing agreements
- 👥 **Up to 10 Participants**: Support for complex collaborative projects
- 💯 **Percentage-Based Distribution**: Define exact revenue splits (up to 100.00%)
- 🔄 **Automatic Distribution**: One-click revenue distribution to all participants
- 💸 **Individual Withdrawals**: Participants can withdraw their earnings anytime

### Governance
- 📝 **Update Proposals**: Propose changes to revenue splits
- ✍️ **Multi-Signature Consensus**: All participants must agree to changes
- 🔐 **Secure Authorization**: Only authorized participants can perform actions
- ⏸️ **Contract Deactivation**: Contract creators can deactivate contracts

## 📋 Usage Instructions

### 1. Creating a Revenue Contract

```clarity
(contract-call? .Revenue-Split-Contract create-revenue-contract
  "My Music Album"
  (list 
    { participant: 'SP1234...ARTIST1, percentage: u5000 }  ;; 50%
    { participant: 'SP5678...PRODUCER, percentage: u3000 } ;; 30%
    { participant: 'SP9012...LABEL, percentage: u2000 }    ;; 20%
  )
)
```

### 2. Depositing Revenue

```clarity
(contract-call? .Revenue-Split-Contract deposit-revenue u1) ;; Contract ID 1
```

### 3. Distributing Revenue

```clarity
(contract-call? .Revenue-Split-Contract distribute-revenue u1)
```

### 4. Withdrawing Earnings

```clarity
(contract-call? .Revenue-Split-Contract withdraw-earnings u1)
```

### 5. Proposing Updates

```clarity
(contract-call? .Revenue-Split-Contract propose-update
  u1  ;; Contract ID
  (list 
    { participant: 'SP1234...ARTIST1, percentage: u6000 }  ;; 60%
    { participant: 'SP5678...PRODUCER, percentage: u4000 } ;; 40%
  )
)
```

### 6. Signing Proposals

```clarity
(contract-call? .Revenue-Split-Contract sign-update u1) ;; Proposal ID
```

## 📖 Read-Only Functions

### Get Contract Information
```clarity
(contract-call? .Revenue-Split-Contract get-contract-info u1)
```

### Check Participant Details
```clarity
(contract-call? .Revenue-Split-Contract get-participant-info u1 'SP1234...ADDRESS)
```

### View Current Balance
```clarity
(contract-call? .Revenue-Split-Contract get-participant-balance u1 'SP1234...ADDRESS)
```

### Monitor Proposals
```clarity
(contract-call? .Revenue-Split-Contract get-proposal-info u1)
(contract-call? .Revenue-Split-Contract has-signed-proposal u1 'SP1234...SIGNER)
```

## ⚠️ Important Notes

### Percentage Rules
- Percentages must sum to exactly **10,000** (representing 100.00%)
- Example: 50% = 5000, 25.5% = 2550
- Maximum 10 participants per contract

### Security Features
- Only active participants can propose updates
- All participants must sign to execute updates
- Contract creators can deactivate contracts
- Funds are securely held in the contract

### Error Codes
- `u100`: Unauthorized access
- `u101`: Invalid percentage (must sum to 10,000)
- `u102`: Insufficient balance
- `u103`: Contract/participant not found
- `u104`: Already exists
- `u105`: Invalid parameters
- `u106`: Consensus required
- `u107`: Already signed

## 🎵 Use Cases

### Music Industry
- **Albums**: Artists, producers, songwriters, and labels
- **Streaming**: Automatic royalty distribution from streaming platforms
- **Live Performances**: Split venue revenue among band members

### Content Creation
- **YouTube Channels**: Revenue sharing among collaborators
- **Podcasts**: Ad revenue distribution
- **Online Courses**: Instructor and platform revenue splits

### Publishing
- **Books**: Author, editor, and publisher revenue sharing
- **Magazines**: Writer and publisher splits
- **Digital Content**: Automated royalty payments

### Entertainment
- **Film Production**: Director, producer, and actor profit sharing
- **Game Development**: Team revenue distribution
- **Art Collaborations**: Joint artwork sales

## 🛠️ Development

### Testing
```bash
npm install
npm test
```

### Deployment
```bash
clarinet deploy --testnet
```

## 🔗 Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity
- **Contract Size**: 292 lines
- **Max Participants**: 10 per contract
- **Precision**: 0.01% (using basis points)

## 🤝 Contributing

Feel free to submit issues and enhancement requests! This contract is designed to be simple, secure, and extensible for various creative industry use cases.

---

*Built with ❤️ for the creative community*
