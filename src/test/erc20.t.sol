/// erc20.t.sol

// Copyright (C) 2015-2019  DappHub, LLC,
// Copyright (C) 2019 lucasvo

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.5.12;

import "ds-test/test.sol";

import "../erc20.sol";

contract ERC20User {
    ERC20 erc20;

    constructor(ERC20 erc20_) public {
        erc20 = erc20_;
    }

    function doTransferFrom(address from, address to, uint amount)
        public
        returns (bool)
    {
        return erc20.transferFrom(from, to, amount);
    }

    function doTransfer(address to, uint amount)
        public
        returns (bool)
    {
        return erc20.transfer(to, amount);
    }

    function doApprove(address recipient, uint amount)
        public
        returns (bool)
    {
        return erc20.approve(recipient, amount);
    }

    function doAllowance(address owner, address spender)
        public
        view
        returns (uint)
    {
        return erc20.allowance(owner, spender);
    }

    function doBalanceOf(address who) public view returns (uint) {
        return erc20.balanceOf(who);
    }

    function doApprove(address usr)
        public
        returns (bool)
    {
        return erc20.approve(usr, uint(-1));
    }
    function doMint(uint wad) public {
        erc20.mint(address(this), wad);
    }
    function doBurn(uint wad) public {
        erc20.burn(address(this), wad);
    }
    function doMint(address usr, uint wad) public {
        erc20.mint(usr, wad);
    }
    function doBurn(address usr, uint wad) public {
        erc20.burn(usr, wad);
    }

}

contract Hevm {
    function warp(uint256) public;
}

contract ERC20Test is DSTest {
    uint constant initialBalanceThis = 1000;

    Hevm    hevm;
    ERC20   erc20;
    address user1;
    address user2;
    address self;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);
        erc20 = createERC20();
        erc20.mint(address(this), initialBalanceThis);
        user1 = address(new ERC20User(erc20));
        user2 = address(new ERC20User(erc20));
        self = address(this);
    }

    function createERC20() internal returns (ERC20) {
        return new ERC20("TEST", "Test");
    }

    function testSetupPrecondition() public {
        assertEq(erc20.balanceOf(self), initialBalanceThis);
    }

    function testTransferCost() public logs_gas {
        erc20.transfer(address(0), 10);
    }

    function testAllowanceStartsAtZero() public logs_gas {
        assertEq(erc20.allowance(user1, user2), 0);
    }

    function testValidTransfers() public logs_gas {
        uint sentAmount = 250;
        emit log_named_address("erc2011111", address(erc20));
        erc20.transfer(user2, sentAmount);
        assertEq(erc20.balanceOf(user2), sentAmount);
        assertEq(erc20.balanceOf(self), initialBalanceThis - sentAmount);
    }

    function testFailWrongAccountTransfers() public logs_gas {
        uint sentAmount = 250;
        erc20.transferFrom(user2, self, sentAmount);
    }

    function testFailInsufficientFundsTransfers() public logs_gas {
        uint sentAmount = 250;
        erc20.transfer(user1, initialBalanceThis - sentAmount);
        erc20.transfer(user2, sentAmount + 1);
    }

    function testApproveSetsAllowance() public logs_gas {
        emit log_named_address("Test", self);
        emit log_named_address("erc20", address(erc20));
        emit log_named_address("Me", self);
        emit log_named_address("User 2", user2);
        erc20.approve(user2, 25);
        assertEq(erc20.allowance(self, user2), 25);
    }

    function testChargesAmountApproved() public logs_gas {
        uint amountApproved = 20;
        erc20.approve(user2, amountApproved);
        assertTrue(ERC20User(user2).doTransferFrom(self, user2, amountApproved));
        assertEq(erc20.balanceOf(self), initialBalanceThis - amountApproved);
    }

    function testFailTransferWithoutApproval() public logs_gas {
        erc20.transfer(user1, 50);
        erc20.transferFrom(user1, self, 1);
    }

    function testFailChargeMoreThanApproved() public logs_gas {
        erc20.transfer(user1, 50);
        ERC20User(user1).doApprove(self, 20);
        erc20.transferFrom(user1, self, 21);
    }
    function testTransferFromSelf() public {
        erc20.transferFrom(self, user1, 50);
        assertEq(erc20.balanceOf(user1), 50);
    }
    function testFailTransferFromSelfNonArbitrarySize() public {
        // you shouldn't be able to evade balance checks by transferring
        // to yourself
        erc20.transferFrom(self, self, erc20.balanceOf(self) + 1);
    }
    function testMintself() public {
        uint mintAmount = 10;
        erc20.mint(address(this), mintAmount);
        assertEq(erc20.balanceOf(self), initialBalanceThis + mintAmount);
    }
    function testMintUser() public {
        uint mintAmount = 10;
        erc20.mint(user1, mintAmount);
        assertEq(erc20.balanceOf(user1), mintAmount);
    }
    function testFailMintUserNoAuth() public {
        ERC20User(user1).doMint(user2, 10);
    }
    function testMintUserAuth() public {
        erc20.rely(user1);
        ERC20User(user1).doMint(user2, 10);
    }

    function testBurn() public {
        uint burnAmount = 10;
        erc20.burn(address(this), burnAmount);
        assertEq(erc20.totalSupply(), initialBalanceThis - burnAmount);
    }
    function testBurnself() public {
        uint burnAmount = 10;
        erc20.burn(address(this), burnAmount);
        assertEq(erc20.balanceOf(self), initialBalanceThis - burnAmount);
    }
    function testBurnUserWithTrust() public {
        uint burnAmount = 10;
        erc20.transfer(user1, burnAmount);
        assertEq(erc20.balanceOf(user1), burnAmount);

        ERC20User(user1).doApprove(self);
        erc20.burn(user1, burnAmount);
        assertEq(erc20.balanceOf(user1), 0);
    }
    function testBurnAuth() public {
        erc20.transfer(user1, 10);
        erc20.rely(user1);
        ERC20User(user1).doBurn(10);
    }
    function testBurnUserAuth() public {
        erc20.transfer(user2, 10);
        ERC20User(user2).doApprove(user1);
        ERC20User(user1).doBurn(user2, 10);
    }

    function testFailUntrustedTransferFrom() public {
        assertEq(erc20.allowance(self, user2), 0);
        ERC20User(user1).doTransferFrom(self, user2, 200);
    }
    function testTrusting() public {
        assertEq(erc20.allowance(self, user2), 0);
        erc20.approve(user2, uint(-1));
        assertEq(erc20.allowance(self, user2), uint(-1));
        erc20.approve(user2, 0);
        assertEq(erc20.allowance(self, user2), 0);
    }
    function testTrustedTransferFrom() public {
        erc20.approve(user1, uint(-1));
        ERC20User(user1).doTransferFrom(self, user2, 200);
        assertEq(erc20.balanceOf(user2), 200);
    }
    function testApproveWillModifyAllowance() public {
        assertEq(erc20.allowance(self, user1), 0);
        assertEq(erc20.balanceOf(user1), 0);
        erc20.approve(user1, 1000);
        assertEq(erc20.allowance(self, user1), 1000);
        ERC20User(user1).doTransferFrom(self, user1, 500);
        assertEq(erc20.balanceOf(user1), 500);
        assertEq(erc20.allowance(self, user1), 500);
    }
    function testApproveWillNotModifyAllowance() public {
        assertEq(erc20.allowance(self, user1), 0);
        assertEq(erc20.balanceOf(user1), 0);
        erc20.approve(user1, uint(-1));
        assertEq(erc20.allowance(self, user1), uint(-1));
        ERC20User(user1).doTransferFrom(self, user1, 1000);
        assertEq(erc20.balanceOf(user1), 1000);
        assertEq(erc20.allowance(self, user1), uint(-1));
    }

    function testerc20Address() public {
        assertEq(address(erc20), address(0x0F1c6673615352379AFC1a60e3D0234101D67eb2));
    }
}
