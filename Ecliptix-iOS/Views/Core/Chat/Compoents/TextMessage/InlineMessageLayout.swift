//
//  InlineMessageLayout.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 20.08.2025.
//

import SwiftUI

@available(iOS 16.0, *)
struct InlineMessageLayout: Layout {
    var spacing: CGFloat = 6
    var belowSpacing: CGFloat = 4
    var headerSpacing: CGFloat = 6

    var lastTextLineW: CGFloat? = nil
    var headerW: CGFloat? = nil

    // MARK: - Helpers
    struct Indices {
        let hasHeader: Bool
        let header: Int?
        let text: Int
        let time: Int
    }

    struct Measurements {
        var headerSize: CGSize = .zero
        var realHeaderSize: CGSize = .zero
        var textSize: CGSize = .zero
        var timeSize: CGSize = .zero
        var lastTextLineWTemp: CGFloat = 0
        var canInline: Bool = false
        var lineH: CGFloat = 0
    }

    struct Cache {
        var indices = Indices(hasHeader: false, header: nil, text: 0, time: 1)
        var maxW: CGFloat = .nan
        var m = Measurements()
    }

    private func makeIndices(_ subviews: Subviews) -> Indices {
        let hasHeader = subviews.count >= 3
        return Indices(
            hasHeader: hasHeader,
            header: hasHeader ? 0 : nil,
            text: hasHeader ? 1 : 0,
            time: hasHeader ? 2 : 1
        )
    }

    private func measure(for maxW: CGFloat, subviews: Subviews, indices: Indices) -> Measurements {
        var out = Measurements()
        let proposal = ProposedViewSize(width: maxW, height: nil)

        if indices.hasHeader, let h = indices.header {
            let natural = subviews[h].sizeThatFits(proposal)
            let targetW = (headerW ?? 0) > 0 ? headerW! : natural.width
            out.headerSize = natural
            out.realHeaderSize = CGSize(width: targetW, height: natural.height)
        }

        out.textSize = subviews[indices.text].sizeThatFits(proposal)
        out.timeSize = subviews[indices.time].sizeThatFits(proposal)

        let lastLine = (lastTextLineW ?? 0) > 0 ? lastTextLineW! : out.textSize.width
        out.lastTextLineWTemp = lastLine
        out.canInline = lastLine + spacing + out.timeSize.width <= maxW
        out.lineH = max(out.textSize.height, out.timeSize.height)

        return out
    }

    // MARK: - Layout protocol

    func makeCache(subviews: Subviews) -> Cache {
        var cache = Cache()
        cache.indices = makeIndices(subviews)
        return cache
    }

    func updateCache(_ cache: inout Cache, subviews: Subviews) {
        cache.indices = makeIndices(subviews)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        guard subviews.count >= 2 else { return .zero }
        let maxW = proposal.width ?? .infinity

        if cache.maxW.isNaN || cache.maxW != maxW {
            cache.maxW = maxW
            cache.m = measure(for: maxW, subviews: subviews, indices: cache.indices)
        }

        var w: CGFloat
        var h: CGFloat

        if cache.m.canInline {
            w = min(maxW, cache.m.textSize.width + spacing + cache.m.timeSize.width)
            h = cache.m.lineH
        } else {
            w = min(cache.m.textSize.width, maxW)
            h = cache.m.textSize.height + belowSpacing + cache.m.timeSize.height
        }

        if cache.indices.hasHeader {
            w = min(maxW, max(w, cache.m.realHeaderSize.width))
            h += cache.m.realHeaderSize.height + headerSpacing
        }

        return CGSize(width: w, height: h)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        guard subviews.count >= 2 else { return }

        let maxW = bounds.width
        if cache.maxW.isNaN || cache.maxW != maxW {
            cache.maxW = maxW
            cache.m = measure(for: maxW, subviews: subviews, indices: cache.indices)
        }

        var y = bounds.minY

        // 1) Header
        if let h = cache.indices.header {
            subviews[h].place(
                at: CGPoint(x: bounds.minX, y: y),
                proposal: .init(width: maxW, height: cache.m.headerSize.height)
            )
            y += cache.m.headerSize.height + headerSpacing
        }

        // 2) Text + Time
        if cache.m.canInline {
            let timeX: CGFloat = {
                if cache.indices.hasHeader || (lastTextLineW ?? 0) > 0 {
                    return bounds.maxX - cache.m.timeSize.width
                } else {
                    return bounds.minX + cache.m.lastTextLineWTemp + spacing
                }
            }()

            subviews[cache.indices.text].place(
                at: CGPoint(x: bounds.minX, y: y),
                proposal: .init(width: cache.m.textSize.width, height: cache.m.textSize.height)
            )
            subviews[cache.indices.time].place(
                at: CGPoint(x: timeX, y: y + cache.m.lineH - cache.m.timeSize.height),
                proposal: .init(width: cache.m.timeSize.width, height: cache.m.timeSize.height)
            )
        } else {
            subviews[cache.indices.text].place(
                at: CGPoint(x: bounds.minX, y: y),
                proposal: .init(width: maxW, height: cache.m.textSize.height)
            )
            subviews[cache.indices.time].place(
                at: CGPoint(x: bounds.maxX - cache.m.timeSize.width,
                            y: y + cache.m.textSize.height + belowSpacing),
                proposal: .init(width: cache.m.timeSize.width, height: cache.m.timeSize.height)
            )
        }
    }
}
