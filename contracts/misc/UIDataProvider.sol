// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';

/**
 * @dev This struct contains both a `Profile` and a `Publication`.
 *
 * @param profile A standard profile struct.
 * @param publication A standard Publication.
 */
struct LatestData {
    Types.Profile profile;
    Types.Publication publication;
}

/**
 * @title UIDataProvider
 * @author Lens Protocol
 *
 * @dev This is a helper contract to fetch a profile and its latest publication in a single call.
 */
contract UIDataProvider {
    ILensHub immutable HUB;

    constructor(ILensHub hub) {
        HUB = hub;
    }

    /**
     * @notice Returns the profile struct and latest publication struct associated with the passed
     * profile ID.
     *
     * @param profileId The profile ID to query.
     *
     * @return LensData A struct containing the `Profile` and the `Publication` queried.
     */
    function getLatestDataByProfile(uint256 profileId) external view returns (LatestData memory) {
        Types.Profile memory profile = HUB.getProfile(profileId);
        uint256 pubCount = profile.pubCount;
        return LatestData(profile, HUB.getPub(profileId, pubCount));
    }
}
