import React, {useState, useEffect} from 'react';
import AppBar from '@material-ui/core/AppBar';
import Button from '@material-ui/core/Button';
import CssBaseline from '@material-ui/core/CssBaseline';
import Grid from '@material-ui/core/Grid';
import Toolbar from '@material-ui/core/Toolbar';
import Typography from '@material-ui/core/Typography';
import { makeStyles } from '@material-ui/core/styles';
import Container from '@material-ui/core/Container';
import CircularProgress from '@material-ui/core/CircularProgress';
import Web3 from 'web3';
import NameRegABI from './contracts/NameReg.json'

const useStyles = makeStyles((theme) => ({
  icon: {
    marginRight: theme.spacing(2),
  },
  heroContent: {
    backgroundColor: theme.palette.background.paper,
    padding: theme.spacing(8, 0, 6),
  },
  heroButtons: {
    marginTop: theme.spacing(4),
  },
  loaderContainer:  {
    height: '100vh',
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    '& > * + *': {
      marginLeft: theme.spacing(2),
    },
  },
}));

export default function App() {
  const classes = useStyles();
  const [refresh, setrefresh] = useState(0);
  const [loading, setLoading] = useState(true);
  const [connectionFailed, updateConnectionFailed] = useState(false);
  const [account, setAccount] = useState('');
  const [nameRegContract, setNameReg] = useState(false);
  
  const loadWeb3 = async () => {
    if (window.ethereum) {
      window.web3 = new Web3(window.ethereum);
      try {
        await window.ethereum.enable();
      } catch(err) {
        updateConnectionFailed(false)
      } finally {
        setLoading(false);
      }
    } else if (window.web3) {
      window.web3 = new Web3(window.web3.currentProvider);
    } else {
      window.alert(
        "Non-Ethereum browser detected. You should consider trying MetaMask!"
      );
    }
  };

  const initContract = async () => {
    if (
      typeof window.ethereum == "undefined" ||
      typeof window.web3 == "undefined"
    ) {
      return;
    }
    const web3 = window.web3;

    let url = window.location.href;
    console.log(url);

    const accounts = await web3.eth.getAccounts();

    if (!accounts.length) {
      return;
    }
    setAccount(accounts[0]);
    const networkId = await web3.eth.net.getId();
    const networkData = NameRegABI?.networks?.[networkId];
    console.log(networkId, networkData)
    if (networkData) {
      const nameReg = new web3.eth.Contract(NameRegABI.abi, networkData.address);
      setNameReg(nameReg);
    } else {
      window.alert("the contract not deployed to detected network.");
    }
  }

  const walletAddress = async () => {
    await window.ethereum.request({
      method: "eth_requestAccounts",
      params: [
        {
          eth_accounts: {},
        },
      ],
    });
    window.location.reload();
  };

  useEffect(() => {
    loadWeb3();
    initContract();

    if (refresh == 1) {
      setrefresh(0);
      initContract();
    }
    //esl
  }, [refresh]);
  const registerName = async (a) => {
    const nameBytes = '0x' + Buffer.from('Mathew').toString('hex').padEnd(64, 0)
    const numBlocks = 5;
    console.log(nameBytes, numBlocks)
    // Get the reservation fee to be paid
    try {
      const value = await nameRegContract.methods.getReservationFee(numBlocks).call();
      console.log(value);
      await nameRegContract.methods
      .register(nameBytes, numBlocks)
      // set to microether so that metamask will not show 0 in the amound field.
      .send({ from: account, value: window.web3.utils.toWei(value, 'microether') });
    } catch (err) {
      console.log(err);
    }
  };
  const getNameData = async () => {
    const nameBytes = '0x' + Buffer.from('Mathew').toString('hex').padEnd(64, 0)
    const result = await nameRegContract.methods.getData(nameBytes).call();
    console.log(result);
  }
  if(loading) {
    return (
      <div className={classes.loaderContainer}>
        <CircularProgress />
      </div>
    )
  }
  return (
    <>
      <CssBaseline />
      <AppBar position="relative">
        <Toolbar>
          <Typography variant="h6" color="inherit" noWrap>
            Name Registration
          </Typography>
        </Toolbar>
      </AppBar>
      <main>
        <div className={classes.heroContent}>
          <Container maxWidth="sm">
            {connectionFailed && (
              <div className={classes.heroButtons}>
                <Grid container spacing={2} justify="center">
                  <Grid item>
                    <Button variant="contained" color="primary">
                      Connect to Metamask
                    </Button>
                  </Grid>
                </Grid>
              </div>
            )}
            {account && (
              <>
              <Typography variant="button" color="inherit">
                Address: {account}
              </Typography>
              <div className={classes.heroButtons}>
                <Grid container spacing={2} justify="center">
                  <Grid item>
                    <Button variant="contained" color="primary" onClick={registerName}>
                      Register Name
                    </Button>
                    <Button variant="contained" color="primary" onClick={getNameData}>
                      Get Name Data
                    </Button>
                  </Grid>
                </Grid>
              </div>
              </>
            )}
          </Container>
        </div>
      </main>
    </>
  );
}