// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title Arrays
 * @dev Utility library for array operations
 */
library Arrays {
    /**
     * @dev Searches a sorted array for a value
     * @param array The sorted array to search
     * @param value The value to find
     * @return True if found, false otherwise
     */
    function find(uint256[] storage array, uint256 value) internal view returns (bool) {
        if (array.length == 0) {
            return false;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = (low + high) / 2;
            if (array[mid] == value) {
                return true;
            } else if (array[mid] < value) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }

        return false;
    }

    /**
     * @dev Removes an element from an array
     * @param array The array to modify
     * @param index The index of the element to remove
     */
    function remove(uint256[] storage array, uint256 index) internal {
        require(index < array.length, "Arrays: index out of bounds");

        for (uint256 i = index; i < array.length - 1; i++) {
            array[i] = array[i + 1];
        }

        array.pop();
    }

    /**
     * @dev Adds an element to a sorted array
     * @param array The sorted array to modify
     * @param value The value to add
     */
    function addSorted(uint256[] storage array, uint256 value) internal {
        if (array.length == 0) {
            array.push(value);
            return;
        }

        uint256 i = 0;
        while (i < array.length && array[i] < value) {
            i++;
        }

        array.push();
        for (uint256 j = array.length - 1; j > i; j--) {
            array[j] = array[j - 1];
        }

        array[i] = value;
    }
}
