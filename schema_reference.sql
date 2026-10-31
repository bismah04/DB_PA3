
CREATE TABLE DivInfo (
  DivisionID INT NOT NULL,
  DivisionName VARCHAR2(50) NOT NULL,
  SubDivID INT NOT NULL,
  SubDivName VARCHAR2(50) NOT NULL,
  PRIMARY KEY ( DivisionID, SubDivID )
);


CREATE TABLE Customers (
  CustomerID VARCHAR2(20) NOT NULL,
  FirstName VARCHAR2(50) NOT NULL,
  LastName VARCHAR2(50) NOT NULL,
  CustomerType VARCHAR2(20) NOT NULL,
  OrgName VARCHAR2(150),
  Address VARCHAR2(255) NOT NULL,
  PhoneNumber VARCHAR2(15),
  Email VARCHAR2(100),
  PRIMARY KEY ( CustomerID )
);

CREATE TABLE ConnectionTypes (
  ConnectionTypeCode INT,
  Description VARCHAR2(50) NOT NULL,
  SanctionedLoad_KW INT,
  PRIMARY KEY ( ConnectionTypeCode )
);

CREATE TABLE Connections (
  ConnectionID VARCHAR2(20) NOT NULL,
  CustomerID VARCHAR2(20) NOT NULL,
  DivisionID INT,
  SubDivID INT,
  ConnectionTypeCode INT,
  InstallationDate DATE NOT NULL,
  MeterType VARCHAR2(50) NOT NULL,
  Status VARCHAR2(50) NOT NULL,
  PRIMARY KEY ( ConnectionID ),
  FOREIGN KEY ( CustomerID ) REFERENCES Customers ( CustomerID ),
  FOREIGN KEY ( ConnectionTypeCode ) REFERENCES ConnectionTypes ( ConnectionTypeCode ),
  FOREIGN KEY ( DivisionID, SubDivID ) REFERENCES DivInfo ( DivisionID,SubDivID )
);

CREATE TABLE Tariff (
  TariffCode VARCHAR2(50) NOT NULL,
  TariffType INT NOT NULL,
  ConnectionTypeCode INT NOT NULL,
  Slab INT NOT NULL,
  StartDate DATE NOT NULL,
  EndDate DATE NOT NULL,
  ThresholdLow_perHour DECIMAL(10,4) NOT NULL,
  ThresholdHigh_perHour DECIMAL(10,4) NOT NULL,
  TarrifDescription VARCHAR2(50) NOT NULL,
  RatePerUnit DECIMAL(10,2) NOT NULL,
  MinAmount DECIMAL(10,2),
  MinUnit INT,
  PRIMARY KEY ( TariffCode ),
  FOREIGN KEY ( ConnectionTypeCode ) REFERENCES ConnectionTypes ( ConnectionTypeCode )
);


CREATE TABLE TaxAuthority (
  TaxAuthorityID VARCHAR2(50) NOT NULL,
  AuthorityName VARCHAR2(50) NOT NULL,
  PRIMARY KEY ( TaxAuthorityID )
);

CREATE TABLE TaxRates (
  ConnectionTypeCode INT,
  TaxType VARCHAR2(50),
  TaxAuthorityID VARCHAR2(50),
  StartDate DATE NOT NULL,
  EndDate DATE NOT NULL,
  Rate DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (ConnectionTypeCode, TaxType, TaxAuthorityID, StartDate, EndDate),
  FOREIGN KEY ( ConnectionTypeCode ) REFERENCES ConnectionTypes ( ConnectionTypeCode ),
  FOREIGN KEY ( TaxAuthorityID ) REFERENCES TaxAuthority ( TaxAuthorityID )
);

CREATE TABLE MeterReadings (
  ConnectionID VARCHAR2(20),
  TStamp DATE NOT NULL,
  Import_PeakReading INT NOT NULL,
  Import_OffPeakReading INT NOT NULL,
  Export_PeakReading INT NOT NULL,
  Export_OffPeakReading INT NOT NULL,
  Status VARCHAR2(20),
  PRIMARY KEY (ConnectionID, TStamp),
  FOREIGN KEY ( ConnectionID ) REFERENCES Connections ( ConnectionID )
);


CREATE TABLE SubsidyProvider (
  ProviderID VARCHAR2(10) NOT NULL,
  ProviderName VARCHAR2(50) NOT NULL,
  PRIMARY KEY ( ProviderID )
);


CREATE TABLE Subsidy (
  SubsidyCode VARCHAR2(30) NOT NULL,
  ProviderID VARCHAR2(10) NOT NULL,
  ConnectionTypeCode INT NOT NULL,
  StartDate DATE NOT NULL,
  EndDate DATE NOT NULL,
  ThresholdLow_perHour DECIMAL(10,4) NOT NULL,
  ThresholdHigh_perHour DECIMAL(10,4) NOT NULL,
  SubsidyDescription VARCHAR2(100) NOT NULL,
  RatePerUnit DECIMAL(10,2) NOT NULL,
  PRIMARY KEY ( SubsidyCode ),
  FOREIGN KEY ( ConnectionTypeCode ) REFERENCES ConnectionTypes ( ConnectionTypeCode ),
  FOREIGN KEY ( ProviderID ) REFERENCES SubsidyProvider ( ProviderID )
);


CREATE TABLE Bill (
  BillID INT NOT NULL,
  ConnectionID VARCHAR2(20),
  BillingMonth INT NOT NULL,
  BillingYear INT NOT NULL,
  BillIssueDate DATE NOT NULL,
  Import_PeakUnits INT,
  Import_OffPeakUnits INT,
  Export_PeakUnits INT,
  Export_OffPeakUnits INT,
  Net_PeakUnits INT,
  Net_OffPeakUnits INT,
  PeakAmount DECIMAL(10,2),
  OffPeakAmount DECIMAL(10,2),
  FixedFee DECIMAL(10,2),
  TaxAmount DECIMAL(10,2),
  Arrears DECIMAL(10,2),
  AdjustmentAmount DECIMAL(10,2),
  SubsidyAmount  DECIMAL(10,2),
  DueDate DATE NOT NULL,
  TotalAmount_BeforeDueDate DECIMAL(10,2),
  TotalAmount_AfterDueDate DECIMAL(10,2),
  PRIMARY KEY (BillID),
  FOREIGN KEY (ConnectionID) REFERENCES Connections ( ConnectionID )
);

CREATE TABLE BillAdjustments (
  AdjustmentID VARCHAR2(50),
  BillID INT,
  AdjustmentAmount DECIMAL(10,2) NOT NULL,
  AdjustmentReason VARCHAR2(255),
  AdjustmentDate DATE,
  OfficerName VARCHAR2 (50),
  OfficerDesignation VARCHAR2 (50),
  OriginalBillAmount NUMBER(10, 2),
  PRIMARY KEY (AdjustmentID),
  FOREIGN KEY (BillID) REFERENCES Bill ( BillID )
);

CREATE TABLE PaymentMethods (
  PaymentMethodID INT,
  PaymentMethodDescription VARCHAR2(50) NOT NULL,
  PRIMARY KEY (PaymentMethodID)
);


CREATE TABLE PaymentDetails (
  BillID INT,
  PaymentDate DATE,
  PaymentStatus VARCHAR2(50) NOT NULL,
  PaymentMethodID INT,
  AmountPaid DECIMAL(10,2),
  PRIMARY KEY (BillID, PaymentDate),
  FOREIGN KEY ( BillID ) REFERENCES Bill ( BillID ),
  FOREIGN KEY ( PaymentMethodID ) REFERENCES PaymentMethods ( PaymentMethodID )
);

CREATE TABLE FixedCharges (
  ConnectionTypeCode INT,
  FixedChargeType VARCHAR2(50),
  TaxAuthorityID VARCHAR2(50),
  StartDate DATE NOT NULL,
  EndDate DATE NOT NULL,
  FixedFee DECIMAL(10, 2) NOT NULL,
  PRIMARY KEY (ConnectionTypeCode, FixedChargeType, TaxAuthorityID, StartDate, EndDate),
  FOREIGN KEY ( ConnectionTypeCode ) REFERENCES ConnectionTypes ( ConnectionTypeCode ),
  FOREIGN KEY ( TaxAuthorityID ) REFERENCES TaxAuthority ( TaxAuthorityID )
);
