// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

// Developed by @Miketoshibtc

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}

contract COSMETICS is ERC1155, Ownable, Pausable, ERC1155Burnable, ERC1155Supply {
    
	address ownersWallet;
    mapping (uint256 => string) private cosmeticType;
    mapping (uint256 => string) private cosmeticMedia;
    mapping (uint256 => string) private cosmeticName;
    mapping (uint256 => string) private cosmeticDesc;
    mapping (uint256 => uint256) private cosmeticLevel;
    mapping (uint256 => uint256) private cosmeticBooster;
    mapping (uint256 => bool) public mintAllowed;
    mapping (uint256 => uint256) public mintMax;
    mapping (uint256 => uint256) public maxSupply;
    mapping (uint256 => uint256) public mintPrice;
    mapping(address => bool) private isAdmin;
    mapping(address => bool) private authorizedMinters;
    
    constructor(address _owners, address admin1, address admin2) ERC1155("") {
        addAdmin(admin1);
        addAdmin(admin2);
        addAuthorizedMinter(admin1);
        addAuthorizedMinter(admin2);
        ownersWallet = _owners;
        setTokenURI(0, "Empty", "There is no cosmetic", "No media to show", "Empty Type", 0, 0);
    }

    modifier onlyAdmin {
		require(isAdmin[msg.sender] || msg.sender == owner());
		_;
	}

    modifier onlyAuthorizedMinters {
		require(authorizedMinters[msg.sender] || msg.sender == owner());
		_;
	}

    function changeownersWallet(address _new) public onlyAdmin {
		ownersWallet = _new;
	}

    function withdraw() public payable onlyAdmin {
		(bool OWNERS, ) = ownersWallet.call{value: address(this).balance}(""); 
		require(OWNERS, "transaction failed");
	}

    function addAdmin (address _add) public onlyAdmin {
		isAdmin[_add] = true;
	}

    function removeAdmin (address _delete) public onlyAdmin {
		isAdmin[_delete] = false;
	}

    function addAuthorizedMinter (address _add) public onlyAdmin {
		authorizedMinters[_add] = true;
	}

    function removeAuthorizedMinter (address _delete) public onlyAdmin {
		authorizedMinters[_delete] = false;
	}

    function setTokenURI(uint256 _tokenId, string memory _name, string memory _desc, string memory _media, string memory _type, uint256 _level, uint256 _booster) public onlyAdmin {
        cosmeticName[_tokenId] = _name;
        cosmeticMedia[_tokenId] = _media;
        cosmeticDesc[_tokenId] = _desc;
        cosmeticType[_tokenId] = _type;
        cosmeticLevel[_tokenId] = _level;
        cosmeticBooster[_tokenId] = _booster;
    }

    function setTokenURIS(uint256[] memory _tokenIds, string[] memory _names, string[] memory _desc, string[] memory _media, string[] memory _types, uint256[] memory _levels, uint256[] memory _boosters) public onlyAdmin {
        require(_tokenIds.length == _names.length, "Diferent length");
        for(uint256 i = 0; i < _tokenIds.length; i++){
            cosmeticName[_tokenIds[i]] = _names[i];
            cosmeticDesc[_tokenIds[i]] = _desc[i];
            cosmeticMedia[_tokenIds[i]] = _media[i];
            cosmeticType[_tokenIds[i]] = _types[i];
            cosmeticLevel[_tokenIds[i]] = _levels[i];
            cosmeticBooster[_tokenIds[i]] = _boosters[i];
        }
    }

    function setMintAllowed(uint256 id, bool allowed) public onlyAdmin {
        mintAllowed[id] = allowed;
    }

    function setMintMax(uint256 id, uint256 newMax) public onlyAdmin {
        mintMax[id] = newMax;
    }

    function setMaxSupply(uint256 id, uint256 newMax) public onlyAdmin {
        maxSupply[id] = newMax;
    }

    function setMintPrice(uint256 id, uint256 newPrice) public onlyAdmin {
        mintPrice[id] = newPrice;
    }

    function uri(uint256 _tokenId) override public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "', cosmeticName[_tokenId],'", "description": "', cosmeticDesc[_tokenId],'", "attributes": [{"trait_type":"Type", "value":"',
                                    cosmeticType[_tokenId],
                                    '"},{"trait_type":"Level", "value":"',
                                    cosmeticLevel[_tokenId].toString(),
                                    '"},{"display_type": "boost_number", "trait_type":"Boost", "value":"',
                                    cosmeticBooster[_tokenId].toString(),
                                    '"}],',
                                    '"image":"',
                                    cosmeticMedia[_tokenId],
                                    '"}'
                                )
                            )
                        )
                    )
                )
            );
    }

    function getCurrentSupply(uint256 _tokenId) public view returns (uint256 currentSupply) {
        return totalSupply(_tokenId);
    }

    function getCosmeticLevel(uint256 _tokenId) public view returns (uint256) {
        return cosmeticLevel[_tokenId];
    }

    function getCosmeticBoost(uint256 _tokenId) public view returns (uint256) {
        return cosmeticBooster[_tokenId];
    }

    function getCosmeticName(uint256 _tokenId) public view returns (string memory) {
        return cosmeticName[_tokenId];
    }

    function getCosmeticDesc(uint256 _tokenId) public view returns (string memory) {
        return cosmeticDesc[_tokenId];
    }

    function getCosmeticType(uint256 _tokenId) public view returns (string memory) {
        return cosmeticType[_tokenId];
    }

    function getCosmeticMedia(uint256 _tokenId) public view returns (string memory) {
        return cosmeticMedia[_tokenId];
    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyAuthorizedMinters
    {
        uint256 supply = totalSupply(id);
        if(maxSupply[id] != 0){
            require(amount+supply <= maxSupply[id], "More than allowed");   
        }
        _mint(account, id, amount, data);
    }

    function publicMint(uint256 id, uint256 amount, bytes memory data) payable public
    {
        require(mintAllowed[id], "Public mint not allowed");
        uint256 supply = totalSupply(id);
        if(maxSupply[id] != 0){
            require(amount+supply <= maxSupply[id], "More than allowed");   
        }
        if(mintMax[id] != 0){
            require(amount <= mintMax[id], "More than allowed");    
        }
        require(msg.value >= mintPrice[id]*amount, "Not enough matic");
        _mint(msg.sender, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyAuthorizedMinters
    {
        for(uint256 i = 0; i < ids.length; i++){
            uint256 supply = totalSupply(ids[i]);
            if(maxSupply[ids[i]] != 0){
                require(amounts[i]+supply <= maxSupply[ids[i]], "More than allowed");    
            }
        }
        _mintBatch(to, ids, amounts, data);
    }

    function airdrop(address[] memory to, uint256 id, uint256 amount, bytes memory data)
        public
        onlyAdmin
    {
        uint256 supply = totalSupply(id);
        if(maxSupply[id] != 0){
            require(amount+supply <= maxSupply[id], "More than allowed");   
        }
        for(uint256 i = 0; i < to.length; i++){
            _mint(to[i], id, amount, data);
        }
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}