// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'test/base/BaseTest.t.sol';

/* Test plan:
 *
 * Test New V2 Publications:
 * - Test that non-existent publication returns type PublicationType.Nonexistent (0)
 * - Create a Post and test that a Post returns type PublicationType.Post (1)
 * - Create a Comment and test that a Comment returns type PublicationType.Comment (2)
 * - Create a Mirror and test that a Mirror returns type PublicationType.Mirror (3)
 * - Create a Quote and test that a Quote returns type PublicationType.Quote (4)
 *
 * Test Legacy V1 Publications:
 * - Create a Post, override the storage to be a legacy V1 Post with PubType 0, and test that a Post returns type PublicationType.Post (1)
 * - Create a Comment, override the storage to be a legacy V1 Comment with PubType 0, and test that a Comment returns type PublicationType.Comment (2)
 * - Create a Mirror, override the storage to be a legacy V1 Mirror with PubType 0, and test that a Mirror returns type PublicationType.Mirror (3)
 */

contract PublicationTypeTest is BaseTest {

}
