import pandas as pd

# %% Open a file
df = pd.read_csv(r'C:\Users\PC\Desktop\google trends\online_retail_II.csv', 
                 encoding = 'ISO-8859-1')

# %% Check data types
print(df.info())

# %% Remove duplicates
df = df.drop_duplicates()

# %% Remove null values
print(df.isnull().sum())
df = df.dropna(subset = ['Description', 'Customer ID'])

# %% Filtering quantity
count = (df['Quantity'] < 0).sum()
print(count)
df = df[df['Quantity'] > 0]

# %% Filtering price
count_price = (df['Price'] <= 0.01).sum()
print(count_price)
df = df[df['Price'] >= 0.01]

# %% Filtering all values with unexpected letters
service_codes = df['StockCode'].str.contains('^[a-zA-Z]+', na=False).sum()
print(service_codes)
df = df[~df['StockCode'].str.contains('^[a-zA-Z]', na=False)]

# %% Change type for date column
df['InvoiceDate'] = pd.to_datetime(df['InvoiceDate'])
print(df.dtypes)

# %% Change type for customer id column
pd.set_option('display.max_columns', None)
print(df.head())
df['Customer ID'] = df['Customer ID'].astype(int).astype(str)

# %% Save final file
df.to_csv(r'D:\online_retail_SQL.csv', index = False)


