import Foundation

enum SnapshotMapper {
    static func map(_ dto: SnapshotDTO) -> BotSnapshot {
        BotSnapshot(
            dashboard: DashboardSummary(
                totalEquity: dto.dashboard.totalEquity,
                balance: dto.dashboard.balance,
                winRate: dto.dashboard.winRate,
                todayPnL: dto.dashboard.todayPnL,
                allTimePnL: dto.dashboard.allTimePnL,
                openPositionsCount: dto.dashboard.openPositionsCount,
                totalTrades: dto.dashboard.totalTrades,
                equityCurve: dto.dashboard.equityCurve.map { EquityPoint(date: $0.date, equity: $0.equity) }
            ),
            portfolio: PortfolioSummary(
                equityCurve: dto.portfolio.equityCurve.map { EquityPoint(date: $0.date, equity: $0.equity) },
                high: dto.portfolio.high,
                low: dto.portfolio.low,
                current: dto.portfolio.current,
                rangeStart: dto.portfolio.rangeStart,
                rangeEnd: dto.portfolio.rangeEnd
            ),
            positions: dto.positions.map {
                Position(
                    id: $0.id,
                    symbol: $0.symbol,
                    side: TradeSide(rawValue: $0.side) ?? .long,
                    entryPrice: $0.entryPrice,
                    currentPrice: $0.currentPrice,
                    quantity: $0.quantity,
                    leverage: $0.leverage,
                    margin: $0.margin,
                    takeProfit: $0.takeProfit,
                    stopLoss: $0.stopLoss,
                    unrealizedPnL: $0.unrealizedPnL,
                    openedAt: $0.openedAt
                )
            },
            trades: dto.trades.map {
                Trade(
                    id: $0.id,
                    closedAt: $0.closedAt,
                    symbol: $0.symbol,
                    side: TradeSide(rawValue: $0.side) ?? .long,
                    entryPrice: $0.entryPrice,
                    exitPrice: $0.exitPrice,
                    pnl: $0.pnl
                )
            },
            insights: InsightFeed(
                vetoLog: dto.insights.vetoLog.map {
                    VetoEntry(
                        id: $0.id,
                        timestamp: $0.timestamp,
                        symbol: $0.symbol,
                        side: $0.side,
                        status: VetoStatus(rawValue: $0.status) ?? .proceed,
                        reason: $0.reason
                    )
                },
                lessons: dto.insights.lessons.map {
                    Lesson(id: $0.id, title: $0.title, detail: $0.detail, tags: $0.tags)
                }
            ),
            breakdown: Breakdown(
                bySymbol: dto.breakdown.bySymbol.map {
                    SymbolBreakdown(symbol: $0.symbol, trades: $0.trades, winRate: $0.winRate, netPnL: $0.netPnL)
                },
                byRegime: dto.breakdown.byRegime.map {
                    RegimeBreakdown(regime: $0.regime, trades: $0.trades, winRate: $0.winRate)
                }
            )
        )
    }

    static func dto(from snapshot: BotSnapshot) -> SnapshotDTO {
        SnapshotDTO(
            dashboard: SnapshotDTO.DashboardDTO(
                totalEquity: snapshot.dashboard.totalEquity,
                balance: snapshot.dashboard.balance,
                winRate: snapshot.dashboard.winRate,
                todayPnL: snapshot.dashboard.todayPnL,
                allTimePnL: snapshot.dashboard.allTimePnL,
                openPositionsCount: snapshot.dashboard.openPositionsCount,
                totalTrades: snapshot.dashboard.totalTrades,
                equityCurve: snapshot.dashboard.equityCurve.map { SnapshotDTO.EquityPointDTO(date: $0.date, equity: $0.equity) }
            ),
            portfolio: SnapshotDTO.PortfolioDTO(
                equityCurve: snapshot.portfolio.equityCurve.map { SnapshotDTO.EquityPointDTO(date: $0.date, equity: $0.equity) },
                high: snapshot.portfolio.high,
                low: snapshot.portfolio.low,
                current: snapshot.portfolio.current,
                rangeStart: snapshot.portfolio.rangeStart,
                rangeEnd: snapshot.portfolio.rangeEnd
            ),
            positions: snapshot.positions.map {
                SnapshotDTO.PositionDTO(id: $0.id, symbol: $0.symbol, side: $0.side.rawValue, entryPrice: $0.entryPrice, currentPrice: $0.currentPrice, quantity: $0.quantity, leverage: $0.leverage, margin: $0.margin, takeProfit: $0.takeProfit, stopLoss: $0.stopLoss, unrealizedPnL: $0.unrealizedPnL, openedAt: $0.openedAt)
            },
            trades: snapshot.trades.map {
                SnapshotDTO.TradeDTO(id: $0.id, closedAt: $0.closedAt, symbol: $0.symbol, side: $0.side.rawValue, entryPrice: $0.entryPrice, exitPrice: $0.exitPrice, pnl: $0.pnl)
            },
            insights: SnapshotDTO.InsightsDTO(
                vetoLog: snapshot.insights.vetoLog.map {
                    SnapshotDTO.VetoEntryDTO(id: $0.id, timestamp: $0.timestamp, symbol: $0.symbol, side: $0.side, status: $0.status.rawValue, reason: $0.reason)
                },
                lessons: snapshot.insights.lessons.map {
                    SnapshotDTO.LessonDTO(id: $0.id, title: $0.title, detail: $0.detail, tags: $0.tags)
                }
            ),
            breakdown: SnapshotDTO.BreakdownDTO(
                bySymbol: snapshot.breakdown.bySymbol.map {
                    SnapshotDTO.SymbolBreakdownDTO(symbol: $0.symbol, trades: $0.trades, winRate: $0.winRate, netPnL: $0.netPnL)
                },
                byRegime: snapshot.breakdown.byRegime.map {
                    SnapshotDTO.RegimeBreakdownDTO(regime: $0.regime, trades: $0.trades, winRate: $0.winRate)
                }
            )
        )
    }
}
