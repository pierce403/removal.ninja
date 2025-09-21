import React from 'react';
import { Link } from 'react-router-dom';
import { useWallet } from '../hooks/useWallet';
import styled from 'styled-components';

const HeaderContainer = styled.header`
  background: white;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  padding: 1rem 0;
  margin-bottom: 2rem;
`;

const Nav = styled.nav`
  display: flex;
  justify-content: space-between;
  align-items: center;
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 1rem;
`;

const Logo = styled(Link)`
  font-size: 1.5rem;
  font-weight: bold;
  color: #007bff;
  text-decoration: none;
  
  &:hover {
    color: #0056b3;
  }
`;

const NavLinks = styled.div`
  display: flex;
  gap: 2rem;
  align-items: center;
`;

const NavLink = styled(Link)`
  color: #333;
  text-decoration: none;
  font-weight: 500;
  
  &:hover {
    color: #007bff;
  }
`;

const WalletSection = styled.div`
  display: flex;
  gap: 1rem;
  align-items: center;
`;

const WalletInfo = styled.div`
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  font-size: 0.9rem;
`;

const Address = styled.span`
  color: #666;
`;

const Balance = styled.span`
  color: #007bff;
  font-weight: 600;
`;

const Header = () => {
  const { account, balance, connectWallet, disconnectWallet, loading } = useWallet();

  const formatAddress = (address) => {
    if (!address) return '';
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  };

  return (
    <HeaderContainer>
      <Nav>
        <Logo to="/">🥷 removal.ninja</Logo>
        
        <NavLinks>
          <NavLink to="/brokers">Data Brokers</NavLink>
          <NavLink to="/processors">Processors</NavLink>
          {account && (
            <>
              <NavLink to="/dashboard">Dashboard</NavLink>
              <NavLink to="/processor-dashboard">Processor</NavLink>
            </>
          )}
        </NavLinks>

        <WalletSection>
          {account ? (
            <>
              <WalletInfo>
                <Address>{formatAddress(account)}</Address>
                <Balance>{parseFloat(balance).toFixed(2)} RN</Balance>
              </WalletInfo>
              <button className="btn btn-secondary" onClick={disconnectWallet}>
                Disconnect
              </button>
            </>
          ) : (
            <button 
              className="btn" 
              onClick={connectWallet}
              disabled={loading}
            >
              {loading ? <span className="loading"></span> : 'Connect Wallet'}
            </button>
          )}
        </WalletSection>
      </Nav>
    </HeaderContainer>
  );
};

export default Header;