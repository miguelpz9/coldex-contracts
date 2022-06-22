// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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

pragma solidity ^0.8.0;

interface ICosmetic {
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
    
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external virtual;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external virtual;

    function getCurrentSupply(uint256 _tokenId) external view returns (uint256 currentSupply);

    function getCosmeticLevel(uint256 _tokenId) external view returns (uint256);

    function getCosmeticBoost(uint256 _tokenId) external view returns (uint256);

    function getCosmeticName(uint256 _tokenId) external view returns (string memory);

    function getCosmeticDesc(uint256 _tokenId) external view returns (string memory);

    function getCosmeticType(uint256 _tokenId) external view returns (string memory);

    function getCosmeticMedia(uint256 _tokenId) external view returns (string memory);
}

contract AvatarCollection is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;

    string[10] traitTypes = ["Background","Eyeball","Eye Color","Iris","Shine","Bottom lid","Top lid","Goo","Empty Type","Empty Type"];

    struct Avatar {
        uint256[10] traits;
        // string imageURI;
        string URI;
        uint256 level;
    }

    ICosmetic public cosmetics;

    mapping(uint256 => Avatar) avatars;

    string public API;
    bool public isPaused = true;
    uint256 public maxSupply = 10000;
    uint256 tokenId = 0;
    uint256 price = 0;
    uint256 updatePrice = 0;
    address ownersWallet;
    mapping(address => bool) private isAdmin;

    constructor(
        address _cosmetics,
        string memory _API,
        address admin1,
        address admin2
    ) ERC721("Avatar", "AVA") {
        addAdmin(admin1);
        addAdmin(admin2);
        cosmetics = ICosmetic(_cosmetics);
        API = _API;
    }

    modifier onlyAdmin {
		require(isAdmin[msg.sender] || msg.sender == owner());
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

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 _tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, _tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function updateCosmeticsAddress(address _cosmetics) public onlyOwner {
        cosmetics = ICosmetic(_cosmetics);
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setUpdatePrice(uint256 _newPrice) public onlyOwner {
        updatePrice = _newPrice;
    }

    function setAPI(string memory _newAPI) public onlyOwner {
        API = _newAPI;
    }

    function setMaxSupply(uint256 _quantity) public onlyOwner {
        maxSupply = _quantity;
    }

    function flipPauseStatus() public onlyOwner {
        isPaused = !isPaused;
    }

    function mint(uint256[10] memory cosmeticIds) public payable {
        require(isPaused == false, "Sale is not active at the moment");
        require(
            totalSupply() < maxSupply,
            "Quantity is greater than remaining Supply"
        );

        require(msg.value >= price, "Not enough money payed");

        Avatar memory newAvatar;

        for(uint256 i = 0; i < 10; i++){
            require(cosmetics.balanceOf(msg.sender, cosmeticIds[i]) > 0, "You dont own the cosmetic");
            require(compareStrings(cosmetics.getCosmeticType(cosmeticIds[i]), traitTypes[i]), "Not in order");
            cosmetics.burn(msg.sender, cosmeticIds[i], 1);
            newAvatar.traits[i] = cosmeticIds[i];
            newAvatar.level += cosmetics.getCosmeticLevel(cosmeticIds[i]);
        }
        newAvatar.level = newAvatar.level/10;
        tokenId++;
        newAvatar.URI = string(abi.encodePacked(
                    API,
                    totalsupply()
        ));
        _safeMint(msg.sender, totalsupply());
        avatars[totalSupply()] = newAvatar;
    }

    function updateCosmetics(uint256[10] memory cosmeticIds, uint256 _tokenId) public payable {
        require(isPaused == false, "Sale is not active at the moment");
        require(ownerOf(_tokenId) == msg.sender, "You dont own this NFT");
        require(msg.value >= updatePrice, "Not enough money payed");

        Avatar memory newAvatar;
        newAvatar.level = 0;

        for(uint256 i = 0; i < 10; i++){
            if(!compareStrings(cosmetics.getCosmeticName(cosmeticIds[i]), cosmetics.getCosmeticName(avatars[_tokenId].traits[i]))){
                require(cosmetics.balanceOf(msg.sender, cosmeticIds[i]) > 0, "You dont own the cosmetic");
                require(compareStrings(cosmetics.getCosmeticType(cosmeticIds[i]), traitTypes[i]), "Not in order");
                cosmetics.burn(msg.sender, cosmeticIds[i], 1);
            }
            newAvatar.traits[i] = cosmeticIds[i];
            newAvatar.level += cosmetics.getCosmeticLevel(cosmeticIds[i]);
        }
        newAvatar.level = newAvatar.level/10;
        newAvatar.URI = avatars[totalSupply()].URI;
        avatars[totalSupply()] = newAvatar;
    }

    function tokensOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(_owner);
        uint256[] memory result = new uint256[](count);
        for (uint256 index = 0; index < count; index++) {
            result[index] = tokenOfOwnerByIndex(_owner, index);
        }
        return result;
    }

    function setTokenURI(string memory _URI, uint256 _tokenId)
        external
        onlyOwner
    {
        avatars[_tokenId].URI = _URI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return avatars[_tokenId].URI;
        // string[] memory names;
        // for(uint256 i = 0; i < 10; i++){
        //     names[i] = cosmetics.getCosmeticName(avatars[_tokenId].traits[i]);
        // }
        // return
        //     string(
        //         abi.encodePacked(
        //             "data:application/json;base64,",
        //             Base64.encode(
        //                 bytes(
        //                     string(
        //                         abi.encodePacked(
        //                             '{"name": "Avatar #',
        //                             _tokenId.toString(),
        //                             '", "attributes": [{"trait_type":"',traitTypes[0],'", "value":"',
        //                             names[0],
        //                             '"},{"trait_type":"',traitTypes[1],'", "value":"',
        //                             names[1],
        //                             '"},{"trait_type":"',traitTypes[2],'", "value":"',
        //                             names[2],
        //                             '"},{"trait_type":"',traitTypes[3],'", "value":"',
        //                             names[3],
        //                             '"},{"trait_type":"',traitTypes[4],'", "value":"',
        //                             names[4],
        //                             '"},{"trait_type":"',traitTypes[5],'", "value":"',
        //                             names[5],
        //                             '"},{"trait_type":"',traitTypes[6],'", "value":"',
        //                             names[6],
        //                             '"},{"trait_type":"',traitTypes[7],'", "value":"',
        //                             names[7],
        //                             '"},{"trait_type":"',traitTypes[8],'", "value":"',
        //                             names[8],
        //                             '"},{"trait_type":"',traitTypes[9],'", "value":"',
        //                             names[9],
        //                             '"}],',
        //                             '"image":"',
        //                             avatars[_tokenId].imageURI,
        //                             '"}'
        //                         )
        //                     )
        //                 )
        //             )
        //         )
        //     );
    }

    function getCosmetics(uint256 _tokenId)
        public
        view
        returns (uint256[10] memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return avatars[_tokenId].traits;
    }

    function getCosmeticsName(uint256 _tokenId)
        public
        view
        returns (string[10] memory cosmeticsName)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        for(uint256 i = 0; i < 10; i++){
            cosmeticsName[i] = cosmetics.getCosmeticName(avatars[_tokenId].traits[i]);
        }
        return cosmeticsName;
    }

    function getLevel(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return avatars[_tokenId].level;
    }


    function totalsupply() private view returns (uint256) {
        return tokenId;
    }
}
