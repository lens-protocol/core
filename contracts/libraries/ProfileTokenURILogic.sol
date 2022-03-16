// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.10;

import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

library ProfileTokenURILogic {
    uint8 internal constant DEFAULT_FONT_SIZE = 24;
    uint8 internal constant MAX_HANDLE_LENGTH_WITH_DEFAULT_FONT_SIZE = 17;

    /**
     * @notice Generates the token URI for the profile NFT.
     *
     * @dev The decoded token URI JSON metadata contains the following fields: name, description, image and attributes.
     * The image field contains a base64-encoded SVG. Both the JSON metadata and the image are generated fully on-chain.
     *
     * @param id The token ID of the profile.
     * @param followers The number of profile's followers.
     * @param owner The address which owns the profile.
     * @param handle The profile's handle.
     * @param imageURI The profile's picture URI. An empty string if has not been set.
     *
     * @return The profile's token URI as a base64-encoded JSON string.
     */
    function getProfileTokenURI(
        uint256 id,
        uint256 followers,
        address owner,
        string memory handle,
        string memory imageURI
    ) external pure returns (string memory) {
        string memory handleWithAtSymbol = string(abi.encodePacked('@', handle));
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            handleWithAtSymbol,
                            '","description":"',
                            handleWithAtSymbol,
                            ' - Lens profile","image":"data:image/svg+xml;base64,',
                            _getSVGImageBase64Encoded(handleWithAtSymbol, imageURI),
                            '","attributes":[{"trait_type":"id","value":"#',
                            Strings.toString(id),
                            '"},{"trait_type":"followers","value":"',
                            Strings.toString(followers),
                            '"},{"trait_type":"owner","value":"',
                            Strings.toHexString(uint160(owner)),
                            '"},{"trait_type":"handle","value":"',
                            handleWithAtSymbol,
                            '"}]}'
                        )
                    )
                )
            );
    }

    /**
     * @notice Generates the token image.
     *
     * @dev If the image URI was set and meets URI format conditions, it will be embedded in the token image.
     * Otherwise, a default picture will be used. Handle font size is a function of handle length.
     *
     * @param handleWithAtSymbol The profile's handle beginning with "@" symbol.
     * @param imageURI The profile's picture URI. An empty string if has not been set.
     *
     * @return The profile token image as a base64-encoded SVG.
     */
    function _getSVGImageBase64Encoded(string memory handleWithAtSymbol, string memory imageURI)
        internal
        pure
        returns (string memory)
    {
        return
            Base64.encode(
                abi.encodePacked(
                    '<svg width="450" height="450" viewBox="0 0 450 450" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><defs><style> @font-face{font-family:"Space Grotesk";src:url(data:application/font-woff;charset=utf-8;base64,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) format("woff"); font-weight:normal;font-style:normal;} </style><linearGradient id="rounded-border-transparency-detail" x1="-137" y1="-236" x2="415" y2="486" gradientUnits="userSpaceOnUse"><stop stop-color="white"/><stop offset="1" stop-color="white" stop-opacity="0.2"/></linearGradient><clipPath id="outer-rounded-border"><rect width="450" height="450" rx="16" fill="white"/></clipPath></defs><g><g clip-path="url(#outer-rounded-border)">',
                    _getSVGProfilePicture(imageURI),
                    '<rect id="bottom-background" y="370" width="450" height="80" fill="#ABFE2C"/><text id="handle" fill="#00501E" text-anchor="middle" dominant-baseline="middle" x="225" y="410" font-family="Space Grotesk" font-size="',
                    Strings.toString(_handleLengthToFontSize(bytes(handleWithAtSymbol).length)),
                    '" font-weight="500" letter-spacing="0em">',
                    handleWithAtSymbol,
                    '</text><rect id="background-border" x="2.5" y="2.5" width="444" height="444" rx="13" stroke="url(#rounded-border-transparency-detail)" stroke-width="5"/><path id="bottom-logo" d="M70 423a14 14 0 0 1-13-1c2 1 5 1 8-1l-1-2h-1a9 9 0 0 1-8 0 9 9 0 0 1-4-6c3-1 11-2 17-8v-1a8 8 0 0 0 3-6c0-2-1-4-3-5-1-2-3-3-5-3l-5 1-3-4c-2-2-4-2-6-2s-4 0-5 2l-3 4-5-1-6 3-2 5a8 8 0 0 0 2 6l1 1c6 6 14 7 17 8a9 9 0 0 1-4 6 9 9 0 0 1-9 0l-2 2h1c2 2 5 2 8 1a14 14 0 0 1-13 1h-1l-1 2 1 1c3 1 7 2 10 1a16 16 0 0 0 10-6v6h3v-6a16 16 0 0 0 13 6l7-1 1-1-2-2Zm-27-29v-1c1-4 4-6 6-6 3 0 6 2 6 6v5l2-3h1v-1c3-2 6-1 8 0 2 2 3 6 0 8v1c-7 7-17 7-17 7s-9 0-16-7l-1-1c-3-2-2-6 0-8l4-1 4 1 1 1 3 3-1-4Z" fill="#fff" fill-opacity=".8"/></g></g></svg>'
                )
            );
    }

    /**
     * @notice Gets the fragment of the SVG correponding to the profile picture.
     *
     * @dev If the image URI was set and meets URI format conditions, this will return an image tag referencing it.
     * Otherwise, a group tag that renders the default picture will be returned.
     *
     * @param imageURI The profile's picture URI. An empty string if has not been set.
     *
     * @return The fragment of the SVG token's image correspondending to the profile picture.
     */
    function _getSVGProfilePicture(string memory imageURI) internal pure returns (string memory) {
        if (_shouldUseCustomPicture(imageURI)) {
            return
                string(
                    abi.encodePacked(
                        '<image id="custom-picture" preserveAspectRatio="xMidYMid slice" height="450" width="450" href="',
                        imageURI,
                        '"/>'
                    )
                );
        } else {
            return
                '<g id="default-picture"><rect id="default-picture-background" x="0" width="450" height="450" fill="#ABFE2C"/><g id="default-picture-logo" transform="translate(60,30)"><style><![CDATA[#ez1M8bKaIyB3_to {animation: ez1M8bKaIyB3_to__to 6000ms linear infinite normal forwards}@keyframes ez1M8bKaIyB3_to__to { 0% { transform: translate3d(0,0,0); transform: translate(161px,137px) rotate(0.05deg);animation-timing-function: cubic-bezier(0.5,0.1,0.7,0.5)} 41% {transform: translate(157px,133px) rotate(0.05deg);animation-timing-function: cubic-bezier(0.2,0.5,0.5,0.9)} 100% {transform: translate(161px,137px) rotate(0.05deg)}} #ez1M8bKaIyB6_to {animation: ez1M8bKaIyB6_to__to 6000ms linear infinite normal forwards}@keyframes ez1M8bKaIyB6_to__to { 0% {transform: translate(160px,136px) rotate(0.05deg);animation-timing-function: cubic-bezier(0.5,0.1,0.7,0.2)} 26% {transform: translate(176px,138px) rotate(0.05deg);animation-timing-function: cubic-bezier(0.2,0.6,0.3,1)} 43% {transform: translate(176px,138px) rotate(0.05deg);animation-timing-function: cubic-bezier(0.2,0.6,0.3,1)} 83% {transform: translate(154px,145px) rotate(0.05deg)} 100% {transform: translate(160px,136px) rotate(0.05deg)}}]]></style><path d="m171.3 315.6.1.2-.3-67a113.6 113.6 0 0 0 99.7 58.6 115 115 0 0 0 48.9-10.8l-5.8-10a103.9 103.9 0 0 1-120.5-25.5l4.3 2.9a77 77 0 0 0 77.9 1l-5.7-10-2 1.1a66.4 66.4 0 0 1-96.5-54c19-1.1-30.8-1.1-12 .1A66.4 66.4 0 0 1 60.9 255l-5.7 10 2.4 1.2a76.1 76.1 0 0 0 79.8-5 103.9 103.9 0 0 1-120.6 25.5l-5.7 9.9a115 115 0 0 0 138.5-32.2c3.8-4.8 7.2-10 10-15.3l.6 66.9v-.4h11Z" fill="#00501e"/><g id="ez1M8bKaIyB3_to" transform="translate(162 137.5)"><g><g transform="translate(-165.4 -143.9)"><path d="M185 159.2c-2.4 6.6-9.6 12.2-19.2 12.2-9.3 0-17.3-5.3-19.4-12.4" fill="none" stroke="#00501e" stroke-width="8.3" stroke-linejoin="round"/><g id="ez1M8bKaIyB6_to" transform="translate(160 136.6)"><g transform="translate(0 -1.3)" fill="#00501e"><path d="M124.8 144.7a11.9 11.9 0 1 1-23.8 0 11.9 11.9 0 0 1 23.8 0Z" transform="translate(-154.1 -145)"/><path d="M209.5 144.7a11.9 11.9 0 1 1-23.8 0 11.9 11.9 0 0 1 23.8 0Z" transform="translate(-155 -145)"/></g></g><path d="M92.2 142.8c0-14.6 13.8-26.4 30.8-26.4s30.8 11.8 30.8 26.4M177 142.8c0-14.6 13.8-26.4 30.8-26.4s30.8 11.8 30.8 26.4" fill="none" stroke="#00501e" stroke-width="8.3" stroke-linejoin="round"/></g></g></g><path d="m219.1 70.3-3.2 3.3.1-4.6v-4.7c-1.8-65.4-100.3-65.4-102.1 0l-.1 4.7v4.6l-3.1-3.3-3.4-3.3C59.8 22-10 91.7 35 139.2l3.3 3.4C92.6 196.8 164.9 197 164.9 197s72.3-.2 126.5-54.4l3.3-3.4C339.7 91.7 270 22 222.5 67l-3.4 3.3Z" fill="none" stroke="#00501e" stroke-width="11.2" stroke-miterlimit="10"/></g></g>';
        }
    }

    /**
     * @notice Maps the handle length to a font size.
     *
     * @dev Gives the font size as a function of handle length using the following formula:
     *
     *      fontSize(handleLength) = 24                              when handleLength <= 17
     *      fontSize(handleLength) = 24 - (handleLength - 12) / 2    when handleLength  > 17
     *
     * @param handleLength The profile's handle length.
     * @return The font size.
     */
    function _handleLengthToFontSize(uint256 handleLength) internal pure returns (uint256) {
        return
            handleLength <= MAX_HANDLE_LENGTH_WITH_DEFAULT_FONT_SIZE
                ? DEFAULT_FONT_SIZE
                : DEFAULT_FONT_SIZE - (handleLength - 12) / 2;
    }

    /**
     * @notice Decides if Profile NFT should use user provided custom profile picture or the default one.
     *
     * @dev It checks if there is a custom imageURI set and makes sure it does not contain double-quotes to prevent
     * injection attacks through the generated SVG.
     *
     * @param imageURI The imageURI set by the profile owner.
     *
     * @return A boolean indicating whether custom profile picture should be used or not.
     */
    function _shouldUseCustomPicture(string memory imageURI) internal pure returns (bool) {
        bytes memory imageURIBytes = bytes(imageURI);
        if (imageURIBytes.length == 0) {
            return false;
        }
        for (uint256 i = 0; i < imageURIBytes.length; i++) {
            if (imageURIBytes[i] == '"') {
                // Avoids embedding a user provided imageURI containing double-quotes to prevent injection attacks
                return false;
            }
        }
        return true;
    }
}
