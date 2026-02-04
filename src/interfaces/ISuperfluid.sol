// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Minimal Superfluid Interfaces for Agentic Guild
 * @notice Only the interfaces we need for GDA (General Distribution Agreement)
 */

interface ISuperToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    
    // Upgrade/downgrade between underlying token and SuperToken
    function upgrade(uint256 amount) external;
    function downgrade(uint256 amount) external;
    
    // Get underlying token
    function getUnderlyingToken() external view returns (address);
    
    // Get decimals
    function decimals() external view returns (uint8);
}

interface ISuperfluidPool {
    function getUnits(address memberAddr) external view returns (uint128);
    function getTotalUnits() external view returns (uint128);
    function updateMemberUnits(address memberAddr, uint128 newUnits) external returns (bool);
    function claimAll(address memberAddr) external returns (bool);
    function claimAll() external returns (bool);
}

interface IGeneralDistributionAgreementV1 {
    function createPool(
        ISuperToken token,
        address admin,
        PoolConfig memory config
    ) external returns (ISuperfluidPool pool);
    
    function distribute(
        ISuperToken token,
        address from,
        ISuperfluidPool pool,
        uint256 requestedAmount
    ) external returns (bool);
    
    function distributeFlow(
        ISuperToken token,
        address from,
        ISuperfluidPool pool,
        int96 requestedFlowRate
    ) external returns (bool);
    
    function getFlowRate(
        ISuperToken token,
        address from,
        ISuperfluidPool pool
    ) external view returns (int96);
}

interface IGDAv1Forwarder {
    function createPool(
        ISuperToken token,
        address admin,
        PoolConfig memory config
    ) external returns (bool success, ISuperfluidPool pool);
    
    function distributeFlow(
        ISuperToken token,
        address from,
        ISuperfluidPool pool,
        int96 requestedFlowRate,
        bytes memory userData
    ) external returns (bool);
    
    function connectPool(
        ISuperfluidPool pool,
        bytes memory userData
    ) external returns (bool);
}

struct PoolConfig {
    bool transferabilityForUnitsOwner;
    bool distributionFromAnyAddress;
}

interface ISuperfluid {
    function getAgreementClass(bytes32 agreementType) external view returns (address);
}

// GDA agreement type identifier
bytes32 constant GDA_TYPE = keccak256("org.superfluid-finance.agreements.GeneralDistributionAgreement.v1");
