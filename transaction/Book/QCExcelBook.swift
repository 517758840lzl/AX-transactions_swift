//
//  QCExcelBook.swift
//  transaction
//

//  Created by Lzl on 2026/10/22.
//

import Foundation

// Não puxei pacote nenhum para exportar. O xlsx é montado aqui à mão, basta abrir no Excel
// O zip vai em store, sem compressão. Comprimido, o Excel antigo diz que o ficheiro está corrompido. Já testei
// TODO: o nome das folhas está fixo em inglês, trocar para o idioma atual quando houver tempo
enum QCExcelBook {
    static func data(book: QCBook, copy: QCLedgerCopy) -> Data {
        let files: [(String, Data)] = [
            ("[Content_Types].xml", Data(contentTypes().utf8)),
            ("_rels/.rels", Data(rootRels().utf8)),
            ("xl/workbook.xml", Data(workbookXml(copy).utf8)),
            ("xl/_rels/workbook.xml.rels", Data(workbookRels().utf8)),
            ("xl/styles.xml", Data(stylesXml().utf8)),
            ("xl/worksheets/sheet1.xml", Data(sheetXml(transactionRows(book, copy)).utf8)),
            ("xl/worksheets/sheet2.xml", Data(sheetXml(accountRows(book, copy)).utf8)),
            ("xl/worksheets/sheet3.xml", Data(sheetXml(budgetRows(book, copy)).utf8)),
        ]
        return zipStore(files)
    }

    private static func transactionRows(_ book: QCBook, _ copy: QCLedgerCopy) -> [[QCCell]] {
        let names = Dictionary(uniqueKeysWithValues: book.accounts.map { ($0.id, $0.name) })
        var rows: [[QCCell]] = [[.text(copy.date), .text(copy.name), .text(copy.category), .text(copy.account), .text(copy.periodSpend), .text(copy.periodIncome)]]
        let entries = book.entries.sorted { $0.date > $1.date }
        for entry in entries {
            let spend: QCCell = entry.isOut ? .number(entry.amount) : .blank
            let income: QCCell = entry.isOut ? .blank : .number(entry.amount)
            rows.append([
                .text(entry.date),
                .text(entry.title),
                .text(entry.category),
                .text(names[entry.accountId] ?? entry.accountName),
                spend,
                income,
            ])
        }
        return rows
    }

    private static func accountRows(_ book: QCBook, _ copy: QCLedgerCopy) -> [[QCCell]] {
        var rows: [[QCCell]] = [[.text(copy.name), .text(copy.accountKindLabel), .text(copy.accountBalance)]]
        for account in book.accounts {
            rows.append([
                .text(account.name),
                .text(copy.accountKind(account.kind)),
                .number(QCBookMath.accountTotal(account, entries: book.entries)),
            ])
        }
        return rows
    }

    private static func budgetRows(_ book: QCBook, _ copy: QCLedgerCopy) -> [[QCCell]] {
        var rows: [[QCCell]] = [[.text(copy.name), .text(copy.amount)]]
        if let monthly = book.monthlyBudget {
            rows.append([.text(copy.monthlyBudget), .number(monthly)])
        }
        for name in book.categoryCaps.keys.sorted() {
            let amount = book.categoryCaps[name] ?? 0
            guard amount > 0 else { continue }
            rows.append([.text(name), .number(amount)])
        }
        return rows
    }

    private enum QCCell {
        case blank
        case text(String)
        case number(Double)
    }

    private static func workbookXml(_ copy: QCLedgerCopy) -> String {
        let names = uniqueSheetNames([copy.transactions, copy.accounts, copy.monthlyBudget])
        let sheets = names.enumerated().map { index, name in
            "<sheet name=\"\(xml(name))\" sheetId=\"\(index + 1)\" r:id=\"rId\(index + 1)\"/>"
        }.joined()
        return "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" +
            "<workbook xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\">" +
            "<sheets>\(sheets)</sheets></workbook>"
    }

    private static func uniqueSheetNames(_ names: [String]) -> [String] {
        var used = Set<String>()
        return names.enumerated().map { index, name in
            let cleaned = String(name.replacingOccurrences(of: "[\\\\/*?:\\[\\]]", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines).prefix(31))
            var next = cleaned.isEmpty ? "Sheet\(index + 1)" : cleaned
            var extra = 2
            while used.contains(next) {
                let suffix = " \(extra)"
                let head = String(cleaned.prefix(31 - suffix.count))
                next = head + suffix
                extra += 1
            }
            used.insert(next)
            return next
        }
    }

    private static func sheetXml(_ rows: [[QCCell]]) -> String {
        let body = rows.enumerated().map { rowIndex, row in
            let cells = row.enumerated().map { column, cell in cellXml(column, rowIndex + 1, cell) }.joined()
            return "<row r=\"\(rowIndex + 1)\">\(cells)</row>"
        }.joined()
        return "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" +
            "<worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\"><sheetData>\(body)</sheetData></worksheet>"
    }

    private static func cellXml(_ column: Int, _ row: Int, _ cell: QCCell) -> String {
        let ref = "\(columnName(column))\(row)"
        switch cell {
        case .blank:
            return ""
        case .text(let value):
            guard !value.isEmpty else { return "" }
            return "<c r=\"\(ref)\" t=\"inlineStr\"><is><t>\(xml(value))</t></is></c>"
        case .number(let value):
            let cents = (value * 100).rounded() / 100
            return "<c r=\"\(ref)\" s=\"1\"><v>\(cents)</v></c>"
        }
    }

    private static func columnName(_ index: Int) -> String {
        var n = index + 1
        var name = ""
        while n > 0 {
            let rem = (n - 1) % 26
            name = String(UnicodeScalar(65 + rem)!) + name
            n = (n - 1) / 26
        }
        return name
    }

    private static func xml(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static func contentTypes() -> String {
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" +
            "<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">" +
            "<Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>" +
            "<Default Extension=\"xml\" ContentType=\"application/xml\"/>" +
            "<Override PartName=\"/xl/workbook.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml\"/>" +
            "<Override PartName=\"/xl/styles.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml\"/>" +
            "<Override PartName=\"/xl/worksheets/sheet1.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>" +
            "<Override PartName=\"/xl/worksheets/sheet2.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>" +
            "<Override PartName=\"/xl/worksheets/sheet3.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>" +
            "</Types>"
    }

    private static func rootRels() -> String {
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" +
            "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">" +
            "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"xl/workbook.xml\"/>" +
            "</Relationships>"
    }

    private static func workbookRels() -> String {
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" +
            "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">" +
            "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet1.xml\"/>" +
            "<Relationship Id=\"rId2\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet2.xml\"/>" +
            "<Relationship Id=\"rId3\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet3.xml\"/>" +
            "<Relationship Id=\"rId4\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles\" Target=\"styles.xml\"/>" +
            "</Relationships>"
    }

    private static func stylesXml() -> String {
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" +
            "<styleSheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">" +
            "<fonts count=\"1\"><font><sz val=\"11\"/><name val=\"Calibri\"/></font></fonts>" +
            "<fills count=\"2\"><fill><patternFill patternType=\"none\"/></fill><fill><patternFill patternType=\"gray125\"/></fill></fills>" +
            "<borders count=\"1\"><border/></borders>" +
            "<cellStyleXfs count=\"1\"><xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\"/></cellStyleXfs>" +
            "<cellXfs count=\"2\">" +
            "<xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\" xfId=\"0\"/>" +
            "<xf numFmtId=\"2\" fontId=\"0\" fillId=\"0\" borderId=\"0\" xfId=\"0\" applyNumberFormat=\"1\"/>" +
            "</cellXfs></styleSheet>"
    }

    private static func zipStore(_ files: [(String, Data)]) -> Data {
        var archive = Data()
        var directory = Data()
        var offset: UInt32 = 0
        for file in files {
            let name = Data(file.0.utf8)
            let crc = crc32(file.1)
            var local = Data()
            local.appendU32(0x04034b50)
            local.appendU16(20)
            local.appendU16(0)
            local.appendU16(0)
            local.appendU16(0)
            local.appendU16(0)
            local.appendU32(crc)
            local.appendU32(UInt32(file.1.count))
            local.appendU32(UInt32(file.1.count))
            local.appendU16(UInt16(name.count))
            local.appendU16(0)
            archive.append(local)
            archive.append(name)
            archive.append(file.1)
            var central = Data()
            central.appendU32(0x02014b50)
            central.appendU16(20)
            central.appendU16(20)
            central.appendU16(0)
            central.appendU16(0)
            central.appendU16(0)
            central.appendU16(0)
            central.appendU32(crc)
            central.appendU32(UInt32(file.1.count))
            central.appendU32(UInt32(file.1.count))
            central.appendU16(UInt16(name.count))
            central.appendU16(0)
            central.appendU16(0)
            central.appendU16(0)
            central.appendU16(0)
            central.appendU32(0)
            central.appendU32(offset)
            directory.append(central)
            directory.append(name)
            offset += UInt32(local.count + name.count + file.1.count)
        }
        archive.append(directory)
        var end = Data()
        end.appendU32(0x06054b50)
        end.appendU16(0)
        end.appendU16(0)
        end.appendU16(UInt16(files.count))
        end.appendU16(UInt16(files.count))
        end.appendU32(UInt32(directory.count))
        end.appendU32(offset)
        end.appendU16(0)
        archive.append(end)
        return archive
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xffffffff
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                let mask = UInt32(bitPattern: -Int32(crc & 1))
                crc = (crc >> 1) ^ (0xedb88320 & mask)
            }
        }
        return crc ^ 0xffffffff
    }
}

private extension Data {
    mutating func appendU16(_ value: UInt16) {
        var little = value.littleEndian
        append(Data(bytes: &little, count: 2))
    }

    mutating func appendU32(_ value: UInt32) {
        var little = value.littleEndian
        append(Data(bytes: &little, count: 4))
    }
}
