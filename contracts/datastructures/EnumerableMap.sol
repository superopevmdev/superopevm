// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title EnumerableMap
 * @dev Library for enumerable key-value mappings
 */
library EnumerableMap {
    struct MapEntry {
        bytes32 key;
        uint256 value;
        bool exists;
    }
    
    struct Map {
        MapEntry[] entries;
        mapping(bytes32 => uint256) indexes;
    }
    
    function set(Map storage map, bytes32 key, uint256 value) internal returns (bool) {
        if (map.indexes[key] != 0) {
            uint256 index = map.indexes[key] - 1;
            map.entries[index].value = value;
            return false;
        } else {
            map.indexes[key] = map.entries.length + 1;
            map.entries.push(MapEntry(key, value, true));
            return true;
        }
    }
    
    function get(Map storage map, bytes32 key) internal view returns (uint256) {
        uint256 index = map.indexes[key];
        require(index != 0, "EnumerableMap: key not found");
        return map.entries[index - 1].value;
    }
    
    function tryGet(Map storage map, bytes32 key) internal view returns (bool, uint256) {
        uint256 index = map.indexes[key];
        if (index == 0) {
            return (false, 0);
        } else {
            return (true, map.entries[index - 1].value);
        }
    }
    
    function remove(Map storage map, bytes32 key) internal returns (bool) {
        uint256 index = map.indexes[key];
        if (index == 0) {
            return false;
        }
        
        uint256 toDeleteIndex = index - 1;
        uint256 lastIndex = map.entries.length - 1;
        
        if (toDeleteIndex != lastIndex) {
            MapEntry storage lastEntry = map.entries[lastIndex];
            map.entries[toDeleteIndex] = lastEntry;
            map.indexes[lastEntry.key] = toDeleteIndex + 1;
        }
        
        map.entries.pop();
        delete map.indexes[key];
        
        return true;
    }
    
    function contains(Map storage map, bytes32 key) internal view returns (bool) {
        return map.indexes[key] != 0;
    }
    
    function length(Map storage map) internal view returns (uint256) {
        return map.entries.length;
    }
    
    function keyAt(Map storage map, uint256 index) internal view returns (bytes32) {
        require(index < map.entries.length, "EnumerableMap: index out of bounds");
        return map.entries[index].key;
    }
    
    function valueAt(Map storage map, uint256 index) internal view returns (uint256) {
        require(index < map.entries.length, "EnumerableMap: index out of bounds");
        return map.entries[index].value;
    }
    
    function keys(Map storage map) internal view returns (bytes32[] memory) {
        bytes32[] memory result = new bytes32[](map.entries.length);
        for (uint256 i = 0; i < map.entries.length; i++) {
            result[i] = map.entries[i].key;
        }
        return result;
    }
    
    function values(Map storage map) internal view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](map.entries.length);
        for (uint256 i = 0; i < map.entries.length; i++) {
            result[i] = map.entries[i].value;
        }
        return result;
    }
}
