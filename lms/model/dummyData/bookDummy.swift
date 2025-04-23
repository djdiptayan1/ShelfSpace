//
//  bookDummy.swift
//  lms
//
//  Created by Diptayan Jash on 23/04/25.
//

import Foundation

let demoBooks: [BookModel] = [
    BookModel(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        libraryId: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
        title: "The Swift Programming Language",
        isbn: "9781491949863",
        description: "An in-depth guide to the Swift language by Apple.",
        totalCopies: 10,
        availableCopies: 7,
        reservedCopies: 1,
        authorIds: [UUID(uuidString: "aaaa1111-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!],
        authorNames: ["Apple Inc."],
        genreIds: [UUID(uuidString: "bbbb1111-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!],
        publishedDate: ISO8601DateFormatter().date(from: "2019-06-04T00:00:00Z"),
        addedOn: ISO8601DateFormatter().date(from: "2025-04-20T12:00:00Z")
    ),
    BookModel(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        libraryId: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
        title: "SwiftUI Essentials",
        isbn: "9781950325022",
        description: "Learn how to build beautiful and modern UIs using SwiftUI.",
        totalCopies: 8,
        availableCopies: 5,
        reservedCopies: 2,
        authorIds: [UUID(uuidString: "aaaa2222-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!],
        authorNames: ["Chris Eidhof"],
        genreIds: [UUID(uuidString: "bbbb2222-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!],
        publishedDate: ISO8601DateFormatter().date(from: "2022-10-15T00:00:00Z"),
        addedOn: ISO8601DateFormatter().date(from: "2025-04-21T09:30:00Z")
    ),
    BookModel(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
        libraryId: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
        title: "Mastering Combine",
        isbn: "9781098119443",
        description: "Understand reactive programming in Swift using Combine.",
        totalCopies: 6,
        availableCopies: 3,
        reservedCopies: 1,
        authorIds: [UUID(uuidString: "aaaa3333-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!],
        authorNames: ["Joseph Heck"],
        genreIds: [UUID(uuidString: "bbbb3333-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!],
        publishedDate: ISO8601DateFormatter().date(from: "2021-03-20T00:00:00Z"),
        addedOn: ISO8601DateFormatter().date(from: "2025-04-22T15:45:00Z")
    ),
    BookModel(
        id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
        libraryId: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
        title: "iOS Development with Swift",
        isbn: "9780135264027",
        description: "Everything you need to start building iOS apps using Swift.",
        totalCopies: 12,
        availableCopies: 9,
        reservedCopies: 2,
        authorIds: [UUID(uuidString: "aaaa4444-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!],
        authorNames: ["Craig Clayton"],
        genreIds: [UUID(uuidString: "bbbb4444-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!],
        publishedDate: ISO8601DateFormatter().date(from: "2020-01-01T00:00:00Z"),
        addedOn: ISO8601DateFormatter().date(from: "2025-04-22T10:00:00Z")
    ),
    BookModel(
        id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
        libraryId: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
        title: "Advanced Swift",
        isbn: "9780983066989",
        description: "A deep dive into advanced Swift programming topics.",
        totalCopies: 5,
        availableCopies: 2,
        reservedCopies: 1,
        authorIds: [
            UUID(uuidString: "aaaa5555-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            UUID(uuidString: "aaaa5556-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        ],
        authorNames: ["Chris Eidhof", "Ole Begemann"],
        genreIds: [UUID(uuidString: "bbbb5555-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!],
        publishedDate: ISO8601DateFormatter().date(from: "2019-09-15T00:00:00Z"),
        addedOn: ISO8601DateFormatter().date(from: "2025-04-23T08:00:00Z")
    )
]
