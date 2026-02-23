import Dependencies
import Foundation
import SQLiteData

// MARK: - Database Setup

/// Creates and migrates the app database at the standard application support location.
func makeAppDatabase() throws -> DatabaseQueue {
	let appSupport = FileManager.default.urls(
		for: .applicationSupportDirectory,
		in: .userDomainMask
	).first! // swiftlint:disable:this force_unwrapping
	let directory = appSupport.appendingPathComponent(AppConstants.appName, isDirectory: true)
	try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
	let path = directory.appendingPathComponent(AppConstants.databaseFileName).path

	var config = Configuration()
	config.foreignKeysEnabled = true
	#if DEBUG
	config.prepareDatabase { database in
		database.trace { print("SQL: \($0)") }
	}
	#endif

	let queue = try DatabaseQueue(path: path, configuration: config)
	try migrateDatabase(queue)
	return queue
}

/// Creates an in-memory database for previews and testing.
func makeInMemoryDatabase() throws -> DatabaseQueue {
	var config = Configuration()
	config.foreignKeysEnabled = true
	let queue = try DatabaseQueue(configuration: config)
	try migrateDatabase(queue)
	return queue
}

// MARK: - Migrations

private func migrateDatabase(_ writer: DatabaseQueue) throws {
	var migrator = DatabaseMigrator()

	#if DEBUG
	migrator.eraseDatabaseOnSchemaChange = true
	#endif

	migrator.registerMigration("v1_initial", migrate: createTables)
	migrator.registerMigration("v1_indexes", migrate: createIndexes)

	try migrator.migrate(writer)
}

private func createTables(_ database: Database) throws {
	try #sql(
		"""
		CREATE TABLE "workDays" (
			"id" TEXT NOT NULL PRIMARY KEY,
			"date" TEXT NOT NULL UNIQUE,
			"isRegistered" INTEGER NOT NULL DEFAULT 0,
			"targetHours" REAL NOT NULL DEFAULT 8.0
		) STRICT
		"""
	)
	.execute(database)

	try #sql(
		"""
		CREATE TABLE "workSessions" (
			"id" TEXT NOT NULL PRIMARY KEY,
			"workDayID" TEXT NOT NULL REFERENCES "workDays"("id") ON DELETE CASCADE,
			"startedAt" TEXT NOT NULL,
			"endedAt" TEXT
		) STRICT
		"""
	)
	.execute(database)

	try #sql(
		"""
		CREATE TABLE "breakSessions" (
			"id" TEXT NOT NULL PRIMARY KEY,
			"workDayID" TEXT NOT NULL REFERENCES "workDays"("id") ON DELETE CASCADE,
			"startedAt" TEXT NOT NULL,
			"endedAt" TEXT
		) STRICT
		"""
	)
	.execute(database)
}

private func createIndexes(_ database: Database) throws {
	try #sql(
		"""
		CREATE INDEX "idx_workSessions_workDayID" ON "workSessions"("workDayID")
		"""
	)
	.execute(database)

	try #sql(
		"""
		CREATE INDEX "idx_breakSessions_workDayID" ON "breakSessions"("workDayID")
		"""
	)
	.execute(database)

	try #sql(
		"""
		CREATE INDEX "idx_workDays_date" ON "workDays"("date")
		"""
	)
	.execute(database)
}
