//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Cluster Membership open source project
//
// Copyright (c) 2018-2019 Apple Inc. and the Swift Cluster Membership project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.md for the list of Swift Cluster Membership project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import ClusterMembership
@testable import CoreMetrics
import Metrics
@testable import SWIM
import XCTest

final class SWIMMetricsTests: XCTestCase {
    let myselfNode = ClusterMembership.Node(protocol: "test", host: "127.0.0.1", port: 7001, uid: 1111)
    let secondNode = ClusterMembership.Node(protocol: "test", host: "127.0.0.1", port: 7002, uid: 2222)
    let thirdNode = ClusterMembership.Node(protocol: "test", host: "127.0.0.1", port: 7003, uid: 3333)
    let fourthNode = ClusterMembership.Node(protocol: "test", host: "127.0.0.1", port: 7004, uid: 4444)
    let fifthNode = ClusterMembership.Node(protocol: "test", host: "127.0.0.1", port: 7005, uid: 5555)

    var myself: TestPeer!
    var second: TestPeer!
    var third: TestPeer!
    var fourth: TestPeer!
    var fifth: TestPeer!

    var testMetrics: TestMetrics!

    override func setUp() {
        super.setUp()
        self.myself = TestPeer(node: self.myselfNode)
        self.second = TestPeer(node: self.secondNode)
        self.third = TestPeer(node: self.thirdNode)
        self.fourth = TestPeer(node: self.fourthNode)
        self.fifth = TestPeer(node: self.fifthNode)

        self.testMetrics = TestMetrics()
        MetricsSystem.bootstrapInternal(self.testMetrics)
    }

    override func tearDown() {
        super.tearDown()
        self.myself = nil
        self.second = nil
        self.third = nil
        self.fourth = nil
        self.fifth = nil

        MetricsSystem.bootstrapInternal(NOOPMetricsHandler.instance)
    }

    // ==== ------------------------------------------------------------------------------------------------------------
    // MARK: Metrics tests

    let alive = [("status", "alive")]
    let unreachable = [("status", "unreachable")]
    let dead = [("status", "dead")]

    func test_members() {
        let swim = SWIM.Instance(settings: .init(), myself: self.myself)
        let m: SWIM.Metrics = swim.metrics

        try XCTAssertEqual(self.testMetrics.expectRecorder(m.membersAlive).lastValue, 1)
        try XCTAssertEqual(self.testMetrics.expectRecorder(m.membersUnreachable).lastValue, 0)
        try XCTAssertEqual(self.testMetrics.expectRecorder(m.membersDead).lastValue, 0)

        _ = swim.addMember(self.second, status: .alive(incarnation: 0))
        try XCTAssertEqual(self.testMetrics.expectRecorder(m.membersAlive).lastValue, 2)
        try XCTAssertEqual(self.testMetrics.expectRecorder(m.membersUnreachable).lastValue, 0)
        try XCTAssertEqual(self.testMetrics.expectRecorder(m.membersDead).lastValue, 0)

        _ = swim.addMember(self.third, status: .alive(incarnation: 0))
        try XCTAssertEqual(self.testMetrics.expectRecorder(m.membersAlive).lastValue, 3)
        try XCTAssertEqual(self.testMetrics.expectRecorder(m.membersUnreachable).lastValue, 0)
        try XCTAssertEqual(self.testMetrics.expectRecorder(m.membersDead).lastValue, 0)

        _ = swim.addMember(self.fourth, status: .alive(incarnation: 0))
        _ = swim.onPeriodicPingTick()
    }
}
